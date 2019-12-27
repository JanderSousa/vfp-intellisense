#Define WM_KEYUP	0x0101
#Define WM_KEYDOWN	0x0100
#Define VK_SHIFT 	0x10
#Define VK_CONTROL 	0x11

#Define WM_LBUTTONDOWN 		0x0201
#Define WM_MBUTTONDOWN		0x0207
#Define WM_RBUTTONDOWN		0x0204
#Define WM_DESTROY			0x0002
#Define GWL_WNDPROC			-4
 
Set Procedure To "EventsControl.prg" Additive

Define Class EventsControl As Custom
	
	HasDebugger = .F.
	SuggestionsCollection = .Null.
	KEY_CONTROL = .F.
	KEY_SHIFT = .F.
	OldProc = 0
	Boundaries = "\,;:)(.[]'=<>+-*/!^%|&#{}?@$" + ["] + ;
		Chr(5) + Chr(24) + Chr(13) + Chr(9) + Chr(32)

	Procedure Init

		If !"FOXTOOLS.FLL" $ Upper(Set("Library"))
			Set Library To (Home()+"FoxTools.Fll") Additive
		Endif

		This.SuggestionsCollection = Newobject("SuggestionsCollection", "SuggestionsCollection.prg")

		This.BindOrUnbind()

		Declare Integer GetWindowLong In Win32API ;
			integer HWnd, Integer nIndex

		Declare Integer GetKeyState In User32 Integer

		Declare Integer CallWindowProc In Win32API ;
			integer lpPrevWndFunc, Integer HWnd, Integer Msg, ;
			integer wParam, Integer Lparam

		This.OldProc = GetWindowLong(_Screen.HWnd, GWL_WNDPROC)

	Endproc

	Procedure BindOrUnbind
		Lparameters Unbind

		If Unbind
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
		Endif

	Endproc

	Procedure HideSuggestVisible
		Local FrmSuggest
		FrmSuggest = This.GetFrmSuggestVisible()
		If !Isnull(FrmSuggest)
			FrmSuggest.Visible = .F.
		Endif	
	EndProc  
	 
	Procedure Eventhandler
		Lparameters HWnd, Msg, wParam, Lparam

		If InList(wParam, 69) and Bittest(GetKeyState(VK_CONTROL), 7)
			MessageBox("Intellisense will be shut down due to conflict with CTRL + S and VFP when an error occurs in execution.")
			Do UninstallIntellisense
		EndIf
			
		Set Console Off
		Sys(2030, 0) 

		This.ChkDebugger()
		If This.HasDebugger
			This.HideSuggestVisible()
			This.BindOrUnbind(.T.)
			CallWindowProc(This.OldProc, HWnd, Msg, wParam, Lparam)
			Sys(2030,1)
			Return
		EndIf

		Local CallW
		CallW = .T. 

		Do Case
			Case Msg = WM_KEYUP
				CallW = This.GetKeyUp(HWnd, Msg, wParam, Lparam)

			Case Msg = WM_KEYDOWN
				CallW = This.GetKeyDown(HWnd, Msg, wParam, Lparam)

			Case Inlist(Msg, WM_LBUTTONDOWN, WM_MBUTTONDOWN, WM_RBUTTONDOWN)
				CallW = This.FrmHideMismatch(HWnd)
				
			Otherwise 
			
		Endcase

		If CallW
			CallWindowProc(This.OldProc, HWnd, Msg, wParam, Lparam)
		Endif

		Set Console On
		Activate Screen
		Sys(2030,1)

	EndProc 

	Procedure FrmHideMismatch
		Lparameters HWnd

		Local i, Suggest
		For i=1 To This.SuggestionsCollection.Count
			Suggest = This.SuggestionsCollection.Item[i]
			Suggest.FrmSuggestion.Visible = Suggest.FrmSuggestion.HWnd = HWnd
		Next
	Endproc

	Procedure GetFrmSuggestVisible
		Lparameters HWnd

		Local i, Suggest
		For i=1 To This.SuggestionsCollection.Count
			Suggest = This.SuggestionsCollection.Item[i]

			If Suggest.FrmSuggestion.Visible
				Return Suggest.FrmSuggestion
			Endif
 
		Next

		Return .Null.
	Endproc

	Procedure GetKeyDown
		Lparameters HWnd, Msg, wParam, Lparam
		Local FrmSuggest, WHandle, Index, Suggest

		This.KEY_CONTROL = Bittest(GetKeyState(VK_CONTROL), 7)
		This.KEY_SHIFT = Bittest(GetKeyState(VK_SHIFT), 7)

		If Inlist(wParam, 192, 221, 57)

			WHandle = This.GetCurrentWindow()
			Index = This.SuggestionsCollection.GetKey(Transform(WHandle))
			If Index = 0
				Return
			EndIf
			
			Suggest = This.SuggestionsCollection.Item[Index]

			Do Case
				Case !This.KEY_SHIFT And wParam = 192
					Suggest.ShowSimpleSuggestions(39, This.KEY_CONTROL)
					Return
				Case This.KEY_SHIFT And wParam = 192
					Suggest.ShowSimpleSuggestions(34, This.KEY_CONTROL)
					Return
				Case !This.KEY_SHIFT And wParam = 221
					Suggest.ShowSimpleSuggestions(91, This.KEY_CONTROL)
					Return
				Case This.KEY_SHIFT And wParam = 221
					Suggest.ShowSimpleSuggestions(123, This.KEY_CONTROL)
					Return
				Case This.KEY_SHIFT And wParam = 57
					Suggest.ShowSimpleSuggestions(40, This.KEY_CONTROL)
					Return
			Endcase
		Endif

		Do Case
			Case This.KEY_SHIFT And Inlist(wParam, 37, 38, 39, 40)
				This.HideSuggestVisible()
				Return

			Case Inlist(wParam, 37, 38, 39)
				FrmSuggest = This.GetFrmSuggestVisible()

				If !Isnull(FrmSuggest)
					If Type("_screen.ActiveForm") = "U" Or ;
							_screen.ActiveForm.HWnd != FrmSuggest.HWnd

						This.HideSuggestVisible()
						Return .T.

					Endif
				Endif

			Case wParam = 40
				FrmSuggest = This.GetFrmSuggestVisible()

				If !Isnull(FrmSuggest)
					If Type("_screen.ActiveForm") = "U" Or ;
							_screen.ActiveForm.HWnd != FrmSuggest.HWnd

						FrmSuggest.lstItems.SetFocus()
						If FrmSuggest.lstItems.ListCount > 1
							FrmSuggest.lstItems.Selected[2] = .T.
						Else
							FrmSuggest.lstItems.Selected[1] = .T.
						Endif

						Return .F.
 
					Endif
				Endif
 
			Case This.KEY_CONTROL And wParam = 83
				This.HideSuggestVisible()

			Case This.KEY_CONTROL And wParam = 32
				Inkey(0.000001)  
				WHandle = This.GetCurrentWindow()
			 	Index = This.SuggestionsCollection.GetKey(Transform(WHandle))
				If Index = 0
					Return
				EndIf 
 
				Return .F.

			Case wParam = 9
				FrmSuggest = This.GetFrmSuggestVisible() 
				If !Isnull(FrmSuggest)
					Inkey(0.000001)
					FrmSuggest.lstItems.KeyPress(9, 0)
					Return .F.		
				EndIf				
		Endcase

	Endproc

	Procedure GetKeyUp
		Lparameters HWnd, Msg, wParam, Lparam
		
		Local WHandle, Suggest, Source, FrmSuggest, ;
			CurrentTextLine, CurrentWord, ObjName, CharPos, Char    
		
		_LastKey = Lastkey()

		If This.KEY_CONTROL	And !Bittest(GetKeyState(VK_CONTROL), 7)
			Return 
		Endif

		If This.KEY_CONTROL And _LastKey = 5
			Return
		EndIf
		
		If This.KEY_SHIFT And Inlist(wParam, 16, 33, 34, 35, 36, 37, 38, 39, 40)
			
			If !(wParam = 16 and _LastKey = 95)
				This.HideSuggestVisible()		
				Return
			EndIf 	
		Endif

		If _LastKey > -1

			If Between(_LastKey, 65, 90) Or Between(_LastKey, 97, 122) Or ;
					Between(_LastKey, 48, 57) Or Inlist(_LastKey, 46, 42, 35, 95, 127, 7) Or ;
					Chr(_LastKey) $ This.Boundaries
					
				WHandle = This.GetCurrentWindow()

	 			Source = This.GetEditSource(WHandle)

				If Inlist(Source, 1, 2, 10)
					Suggest = This.SuggestionsCollection.GetOrAddSuggest(WHandle)
  
			 		If (!This.KEY_CONTROL And Chr(_LastKey) $ This.Boundaries)
						Suggest.AddCurretWord(_LastKey)
						This.HideSuggestVisible()
						
						If _LastKey = 46
							Return Suggest.ShowPemSuggestions()							
						EndIf 
					Else
						If Suggest.ShowPemSuggestions()
							Return .T.
						EndIf 
						
						Suggest.ShowSimpleSuggestions(_LastKey, This.KEY_CONTROL)
					Endif
				EndIf 
 
			EndIf 

		Endif

	Endproc

	Procedure GetCurrentWindow

		Local WHandle
		WHandle = _WOnTop()
		If WHandle <= 0
			Return 0
		Endif
		If This.GetEditSource(WHandle) == -1
			WHandle = 0
		Endif

		Return WHandle
	Endproc

	Procedure GetEditSource
		Lparameters WHandle

		Local Env[25], OK, err
		err = On("Error")
		On Error OK = 0

		OK = _EdGetEnv(WHandle, @Env)

		If Empty(err)
			On Error
		Else
			On Error &err
		Endif

		If Empty(OK)
			Return -1
		Endif

		Return Env[25]
	Endproc

	Protected Procedure ChkDebugger
		If Wvisible("visual foxpro debugger") And !This.HasDebugger
			Local DebugHwnd

			DebugHwnd = This.GetDebuggerHwnd()
			This.HasDebugger = .T.

			Bindevent(DebugHwnd, WM_DESTROY, This, "ReStartIntelliSense", 4)
			Return .F.
		Endif
	Endproc

	Protected Procedure GetDebuggerHwnd
		Set Console Off

		Declare Integer GetActiveWindow In win32api As xxfcpWinAPI_GetActiveWindow
		Declare Integer GetWindow In Win32API As xxfcpWinAPI_GetWindow Integer HWnd, Integer nType
		Declare Integer GetWindowText In Win32API As xxfcpWinAPI_GetWindowText Integer HWnd, String @cText, Integer nType

		Local ActNext, WText
		ActNext = xxfcpWinAPI_GetActiveWindow()

		Do While ActNext<>0
			WText = Replicate(Chr(0), 80)
			xxfcpWinAPI_GetWindowText(ActNext,@WText, 80)
			If "visual foxpro debugger" $ Lower(WText)
				Return ActNext
			Endif
			ActNext = xxfcpWinAPI_GetWindow(ActNext, 2)
		Enddo

		Clear Dlls "xxfcpWinAPI_GetActiveWindow","xxfcpWinAPI_GetWindow","xxfcpWinAPI_GetWindowText"

	Endproc

	Protected Procedure ReStartIntelliSense
		Lparameters HWnd, Msg, wParam, Lparam
		Unbindevents(HWnd, Msg)

		This.BindOrUnbind()

		Sys(2030, 1)
		This.HasDebugger = .F.
	Endproc

Enddefine
