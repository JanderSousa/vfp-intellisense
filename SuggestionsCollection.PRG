Define Class SuggestionsCollection As Collection

	Procedure GetOrAddSuggest
		Lparameters WHandle

		Local Index
		Index = This.GetKey(Transform(WHandle))

		If Index = 0

			This.Add(NewObject("Suggestions", "Suggestions.prg", "", WHandle), Transform(WHandle))
			Index = This.GetKey(Transform(WHandle))		

		Endif

		Return This.Item[Index]

	EndProc
	
Enddefine