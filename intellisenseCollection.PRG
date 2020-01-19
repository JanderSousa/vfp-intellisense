Define Class IntellisenseCollection As Collection

	#define WM_NCDESTROY 0x0082

	Editor = .Null.

	Procedure Init

		This.Editor = Newobject("Editor", "Editor.prg")

	Endproc

	Procedure TryToStart

		Local nWinHandle, nHWND, oWinEnvironment, oIntellisense
		nWinHandle = This.Editor.GetActiveWindowHandle()

		* Did not find window
		If nWinHandle < 1
			Return .Null.
		EndIf
		
		nHWND = This.Editor.WhToHWND(nWinHandle)

		nIndex = This.GetKey(Transform(nHWND))

		* Already started
		If nIndex > 0
			oIntellisense = This.Item(nIndex)
			Return oIntellisense
		Endif

		oWinEnvironment = This.Editor.GetWindowEnvironment(nWinHandle)

		If Isnull(oWinEnvironment)
			Return .Null.
		Endif

		If Inlist(oWinEnvironment.Kind, oWinEnvironment.ED_PROGRAM, oWinEnvironment.ED_SNIP)
			oIntellisense = Newobject("Intellisense", "Intellisense.prg", "", nWinHandle)
			This.Add(oIntellisense, Transform(nHWND))

			Bindevent(oIntellisense.HWnd, WM_NCDESTROY, This, "EventHandler")
			
			Return oIntellisense
		Endif

		Return .Null.

	EndProc
	
	Procedure GetIntellisense(HWnd)
		Local nIndex
		nIndex = This.GetKey(Transform(HWnd))
		
		If nIndex = 0
			Return .Null.
		EndIf 
		
		Return This.Item[nIndex]
		
	EndProc 

	Procedure Eventhandler(HWnd, Msg, wParam, Lparam)
		
		Local nIndex 
		Do Case
			Case Msg = WM_NCDESTROY
				nIndex = This.GetKey(Transform(HWnd))

				If nIndex > 0
					This.Remove(nIndex)
				EndIf
		Endcase

	Endproc

Enddefine
