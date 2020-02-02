Define Class Events As Custom

	#Define WM_ACTIVATE    	0x0006
	#Define WM_KILLFOCUS   	0x0008
	#Define WM_SETFOCUS    	0x0007
	#Define WM_CLOSE       	0x0010
	#Define WM_KEYUP       	0x0101
	#Define WM_KEYDOWN     	0x0100
	#Define WM_LBUTTONDOWN 	0x0201
	#Define WM_MBUTTONDOWN 	0x0207
	#Define WM_RBUTTONDOWN 	0x0204
	#define WM_MOUSEWHEEL	0x020A
	#Define WM_DESTROY     	0x0002

	#Define GWL_WNDPROC    -4

	Dimension Environment[9]

	Enabled = .T.

	HasDebugger = .F.
	KEY_CONTROL = .F.
	KEY_SHIFT = .F.
	OldProc = 0
	Boundaries = "\,;:)(.[]'=<>+-*/!^%|&#{}?@$" + ["] + Chr(5) + Chr(24) + Chr(13) + Chr(9) + Chr(32)

	IntellisenseCollection = .Null.
	VirtualKeyCodes = .Null.

	Procedure Init

		This.VirtualKeyCodes = Newobject("VirtualKeyCodes", "VirtualKeyCodes.PRG")
		This.IntellisenseCollection = Newobject("IntellisenseCollection", "IntellisenseCollection.prg")
		This.BindOrUnbind()
		This.Declare()
		This.OldProc = ___GetWindowLong(_Screen.HWnd, GWL_WNDPROC)

	Endproc

	Procedure Eventhandler(HWnd, Msg, wParam, Lparam)
		
		Sys(2030, 0)
		Set Console Off

		This.SetEnvironment(1)

		This.GetEventhandler(HWnd, Msg, wParam, Lparam)

		This.SetEnvironment(0)

		Set Console On
		Activate Screen
		Sys(2030,1)

	Endproc

	Procedure GetEventhandler(HWnd, Msg, wParam, Lparam)

		If !This.Enabled
			___CallWindowProc(This.OldProc, HWnd, Msg, wParam, Lparam)
			Return
		Endif

		If Inlist(wParam, This.VirtualKeyCodes.E) And ;
				Bittest(___GetKeyState(This.VirtualKeyCodes.Control), 7)
			This.HideSuggestVisible()
			Return
		Endif

		This.ChkDebugger()
		If This.HasDebugger
			This.HideSuggestVisible()
			This.BindOrUnbind(.T.)
			___CallWindowProc(This.OldProc, HWnd, Msg, wParam, Lparam)
			Return
		Endif

		Local cCallW
		cCallW = .T.

		Do Case
			Case Msg = WM_KEYUP
				cCallW = This.GetKeyUp(HWnd, Msg, wParam, Lparam)

			Case Msg = WM_KEYDOWN
				cCallW = This.GetKeyDown(HWnd, Msg, wParam, Lparam)

			Case Inlist(Msg, WM_LBUTTONDOWN, WM_MBUTTONDOWN, WM_RBUTTONDOWN, WM_MOUSEWHEEL)
				cCallW = This.FrmHideMismatch(HWnd)

			Otherwise

		Endcase

		If cCallW
			___CallWindowProc(This.OldProc, HWnd, Msg, wParam, Lparam)
		Endif

	Endproc

	Procedure Declare

		Declare Integer GetActiveWindow In win32api As ___fcpWinAPI_GetActiveWindow
		Declare Integer GetWindow In Win32API As ___fcpWinAPI_GetWindow Integer HWnd, Integer nType
		Declare Integer GetWindowText In Win32API As ___fcpWinAPI_GetWindowText Integer HWnd, String @cText, Integer nType
		Declare Integer GetWindowLong In Win32API As ___GetWindowLong Integer HWnd, Integer nIndex
		Declare Integer CallWindowProc In Win32API As ___CallWindowProc Integer lpPrevWndFunc, Integer HWnd, Integer Msg, Integer wParam, Integer Lparam
		Declare Integer GetKeyState In User32 As ___GetKeyState Integer

	Endproc

	Procedure SetEnvironment(nMode)

		If nMode = 1
			This.Environment[1] = Set("TALK")
			This.Environment[2] = Set("NOTIFY",2)
			This.Environment[3] = Set("ESCAPE")
			This.Environment[4] = Set("EXCLUSIVE")
			This.Environment[5] = Set("UDFPARMS")
			This.Environment[6] = Set("EXACT")
			This.Environment[7] = Set("MESSAGE",1)
			This.Environment[8] = 0
			This.Environment[9] = _Tally

			Set Talk Off
			Set Notify Cursor Off
			Set Escape Off
			Set Exclusive Off
			Set Udfparms To Value
			Set Exact Off

		Else
			If This.Environment[1]="ON"
				Set Talk On
			Endif
			If This.Environment[2]="ON"
				Set Notify Cursor On
			Endif
			If This.Environment[3]="ON"
				Set Escape On
			Endif
			If This.Environment[4]="ON"
				Set Exclusive On
			Endif
			If This.Environment[5]="REFERENCE"
				Set Udfparms To Reference
			Endif
			If This.Environment[6]="ON"
				Set Exact On
			Endif

			_Tally = This.Environment[9]
		Endif
	Endproc

	Procedure BindOrUnbind(lUnbind)

		If lUnbind
			Unbindevent(0, WM_KEYUP)
			Unbindevent(0, WM_KEYDOWN)
			Unbindevent(0, WM_LBUTTONDOWN)
			Unbindevent(0, WM_MBUTTONDOWN)
			Unbindevent(0, WM_RBUTTONDOWN)
		Else
			Bindevent(0, WM_KEYUP, This, "EventHandler")
			Bindevent(0, WM_KEYDOWN, This, "EventHandler")
			Bindevent(0, WM_LBUTTONDOWN, This, "EventHandler")
			Bindevent(0, WM_MBUTTONDOWN, This, "EventHandler")
			Bindevent(0, WM_RBUTTONDOWN, This, "EventHandler")
			Bindevent(0, WM_MOUSEWHEEL, This, "EventHandler")
		Endif

	Endproc

	Procedure HideSuggestVisible
		Local oFrmSuggest, oFrmTooltip
		
		oFrmSuggest = This.GetFrmSuggestVisible()
		If !Isnull(oFrmSuggest)
			oFrmSuggest.Visible = .F.
			
			oFrmTooltip = This.GetFrmTooltipVisible()
			If !IsNull(oFrmTooltip)
				oFrmTooltip.Visible = .F.
			EndIf 
		Endif
	Endproc

	Procedure FrmHideMismatch
		Lparameters HWnd

		Local i, oIntellisense, oFrmSuggestion, oFrmTooltip, lVisible 
		For i=1 To This.IntellisenseCollection.Count
			oIntellisense = This.IntellisenseCollection.Item[i]

			oFrmSuggestion = oIntellisense.FrmSuggestion
			oFrmTooltip = oIntellisense.FrmTooltip

			If Vartype(oFrmSuggestion) != "O"
				Loop
			EndIf
			
			lVisible = oFrmSuggestion.HWnd = HWnd
			
			If !oFrmSuggestion.Visible and lVisible
				oFrmSuggestion.Visible = lVisible				 	
			EndIf 
			
			If !lVisible
				oFrmSuggestion.Visible = .F.
			EndIf 

			If oFrmTooltip.Visible
				oFrmTooltip.Visible = oFrmSuggestion.Visible
			Endif
		Next
	Endproc

	Procedure GetFrmSuggestVisible
		Lparameters HWnd

		Local i, oIntellisense
		For i=1 To This.IntellisenseCollection.Count
			oIntellisense = This.IntellisenseCollection.Item[i]

			If oIntellisense.FrmSuggestion.Visible
				Return oIntellisense.FrmSuggestion
			Endif

		Next

		Return .Null.
	Endproc


	Procedure GetFrmTooltipVisible
		Lparameters HWnd

		Local i, oIntellisense
		For i=1 To This.IntellisenseCollection.Count
			oIntellisense = This.IntellisenseCollection.Item[i]

			If oIntellisense.FrmTooltip.Visible
				Return oIntellisense.FrmTooltip
			Endif

		Next

		Return .Null.
	Endproc

	Procedure GetKeyDown
		Lparameters HWnd, Msg, wParam, Lparam
		Local oFrmSuggest, oIntellisense

		With This.VirtualKeyCodes

			This.KEY_CONTROL = Bittest(___GetKeyState(.Control), 7)
			This.KEY_SHIFT = Bittest(___GetKeyState(.Shift), 7)
			
			If !This.KEY_CONTROL And wParam = .Space
				oIntellisense = This.IntellisenseCollection.TryToStart()
				If !Isnull(oIntellisense)
					oIntellisense.AddCurretWord(.Space)
				EndIf
				
				Return This.HideSuggestVisible()
			EndIf 
			
			If Inlist(wParam, .OEM_3, .OEM_6, .NINE)

				oIntellisense = This.IntellisenseCollection.TryToStart()

				If Isnull(oIntellisense)
					Return
				Endif

				Do Case
					Case !This.KEY_SHIFT And wParam = .OEM_3
						Return oIntellisense.ShowSimpleSuggestions(39, This.KEY_CONTROL)

					Case This.KEY_SHIFT And wParam = .OEM_3
						Return oIntellisense.ShowSimpleSuggestions(34, This.KEY_CONTROL)

					Case !This.KEY_SHIFT And wParam = .OEM_6
						Return oIntellisense.ShowSimpleSuggestions(91, This.KEY_CONTROL)

					Case This.KEY_SHIFT And wParam = .OEM_6
						Return oIntellisense.ShowSimpleSuggestions(123, This.KEY_CONTROL)

					Case This.KEY_SHIFT And wParam = .NINE
						Return oIntellisense.ShowSimpleSuggestions(40, This.KEY_CONTROL)

				Endcase
			Endif

			Do Case
				Case This.KEY_SHIFT And Inlist(wParam, .Left, .UP, .Right, .Down)
					Return This.HideSuggestVisible()

				Case Inlist(wParam, .Left, .UP, .Right)
					oFrmSuggest = This.GetFrmSuggestVisible()

					If !Isnull(oFrmSuggest)
						If Type("_screen.ActiveForm") = "U" Or ;
								_screen.ActiveForm.HWnd != oFrmSuggest.HWnd

							Return This.HideSuggestVisible()

						Endif
					Endif

				Case wParam = .Down
					oFrmSuggest = This.GetFrmSuggestVisible()

					If !Isnull(oFrmSuggest)
						If Type("_screen.ActiveForm") = "U" Or _Screen.ActiveForm.HWnd != oFrmSuggest.HWnd

							oFrmSuggest.lstItems.SetFocus()
							If oFrmSuggest.lstItems.ListCount > 1
								oFrmSuggest.lstItems.Selected[2] = .T.
							Else
								oFrmSuggest.lstItems.Selected[1] = .T.
							Endif

							Return .F.

						Endif
					Endif

				Case This.KEY_CONTROL And wParam = .S
					Return This.HideSuggestVisible()

				Case This.KEY_CONTROL And wParam = .Space
					Inkey(0.000001)

				Case wParam = .Tab
					oFrmSuggest = This.GetFrmSuggestVisible()
					If !Isnull(oFrmSuggest)
						Inkey(0.000001)
						oFrmSuggest.lstItems.KeyPress(.Tab, 0)
						Return .F.
					Endif
			Endcase

		Endwith

	Endproc

	Procedure GetKeyUp
		Lparameters HWnd, Msg, wParam, Lparam

		Local oIntellisense, nLastKey

		nLastKey = Lastkey()

		With This.VirtualKeyCodes

			If This.KEY_CONTROL And !Bittest(___GetKeyState(.Control), 7)
				Return
			EndIf
			
			If !This.KEY_CONTROL And wParam = .Space
				Return This.HideSuggestVisible()
			EndIf 			

			If This.KEY_CONTROL And nLastKey = 5
				Return
			Endif

			If This.KEY_SHIFT And Inlist(wParam, .Shift, .PRIOR, .Next, .End, .Home, .Left, .UP, .Right, .Down)

				If !(wParam = .Shift And nLastKey = 95)
					This.HideSuggestVisible()
					Return
				Endif
			Endif

			If nLastKey > -1

				If Between(nLastKey, 65, 90) Or Between(nLastKey, 97, 122) Or ;
						Between(nLastKey, 48, 57) Or Inlist(nLastKey, 46, 42, 35, 95, 127, 7) Or ;
						Chr(nLastKey) $ This.Boundaries

					oIntellisense = This.IntellisenseCollection.TryToStart()

					If Isnull(oIntellisense)
						Return
					Endif

					If (!This.KEY_CONTROL And Chr(nLastKey) $ This.Boundaries)
						oIntellisense.AddCurretWord(nLastKey)
						This.HideSuggestVisible()

						If nLastKey = 46
							Return oIntellisense.ShowPemSuggestions()
						Endif
					Else
						If oIntellisense.ShowPemSuggestions()
							Return .T.
						Endif

						oIntellisense.ShowSimpleSuggestions(nLastKey, This.KEY_CONTROL)
					Endif

				Endif

			Endif

		Endwith

	Endproc

	Protected Procedure ChkDebugger
		If Wvisible("visual foxpro debugger") And !This.HasDebugger
			Local nDebugHwnd

			nDebugHwnd = This.GetDebuggerHwnd()
			This.HasDebugger = .T.

			Bindevent(nDebugHwnd, WM_DESTROY, This, "ReStartIntelliSense", 4)
			Return .F.
		Endif
	Endproc

	Protected Procedure GetDebuggerHwnd
		Set Console Off

		Local nActNext, cWText
		nActNext = ___fcpWinAPI_GetActiveWindow()

		Do While nActNext<>0
			cWText = Replicate(Chr(0), 80)
			___fcpWinAPI_GetWindowText(nActNext,@cWText, 80)
			If "visual foxpro debugger" $ Lower(cWText)
				Return nActNext
			Endif
			nActNext = ___fcpWinAPI_GetWindow(nActNext, 2)
		Enddo

	Endproc

	Procedure SetEnable
		This.BindOrUnbind()
		This.Enabled = .T.
	Endproc

	Protected Procedure ReStartIntelliSense
		Lparameters HWnd, Msg, wParam, Lparam
		Unbindevents(HWnd, Msg)

		This.BindOrUnbind()

		Sys(2030, 1)
		This.HasDebugger = .F.
	Endproc

Enddefine
