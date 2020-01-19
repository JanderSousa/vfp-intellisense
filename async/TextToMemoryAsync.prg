Define class LoadTextAsync As Session olepublic
	Boundaries = "\,;:)(.[]'=<>+-*/!^%|&#{}?@$" + ["] + Chr(13) + Chr(10) + Chr(32) + Chr(9)
	
	Procedure TextToMemoryAsync(oCallback)

		Local cAllText, cNewText, nSteps, nLenStep, cRestWord,;
			cCharRight, nAt, i, j, cWord
		
		nItemsCount = 0
		
		cAllText = oCallback.AllText

		nLenStep = 250
		nSteps = Max(Ceiling(Len(cAllText) / nLenStep), nLenStep)

		cRestWord = ""
		For i = 1 To nSteps
			
			cNewText = cRestWord + Substr(cAllText, (nLenStep * (i-1))+1, nLenStep)
			cRestWord = ""

			If Empty(cNewText)
				Exit
			Endif

			If i != nSteps
				Do While !Empty(cNewText)
					cCharRight = Right(cNewText, 1)
					If cCharRight $ This.Boundaries
						Exit
					Endif

					cRestWord = cCharRight + cRestWord
					nAt = At(cCharRight, cNewText, Max(Occurs(cCharRight, cNewText), 1))-1
					cNewText = Substr(cNewText, 1, nAt)
				Enddo
			Endif

			For j=1 To Getwordcount(cNewText , This.Boundaries)
				cWord = Padr(Getwordnum(cNewText , j, This.Boundaries), 40)
				oCallback.AddWord(cWord)
			Next

		Next
		
	EndProc

EndDefine

