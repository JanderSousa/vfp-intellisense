Define Class IntellisenseCollection As Collection
	
	Editor = .Null.
	
	Procedure Init
	
		This.Editor = NewObject("Editor", "Editor.prg")
		
	EndProc
	
	Procedure TryToStart
		
		Local nWinHandle, oWinEnvironment, oIntellisense
		nWinHandle = This.Editor.GetActiveWindowHandle()
		
		* Did not find window
		If nWinHandle < 1
			Return .Null.
		EndIf 
			
		nIndex = This.GetKey(Transform(nWinHandle))
		
		* Already started
		If nIndex > 0
			Return This.Item(nIndex)
		EndIf 
			
		oWinEnvironment = This.Editor.GetWindowEnvironment(nWinHandle)
		
		If IsNull(oWinEnvironment)
			Return .Null.
		EndIf 
		
		If InList(oWinEnvironment.Kind, oWinEnvironment.ED_PROGRAM, oWinEnvironment.ED_SNIP)
			oIntellisense = NewObject("Intellisense", "Intellisense.prg", "", nWinHandle)
			This.Add(oIntellisense, Transform(nWinHandle))
			Return oIntellisense
		EndIf 
		
		Return .Null.
		
	EndProc 
	
EndDefine 
