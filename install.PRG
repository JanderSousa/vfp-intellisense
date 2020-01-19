Local cPath
cPath = sys(5) + sys(2003)

Set Path to (cPath) additive
Set Path To (cPath + "\Async") additive

If !PemStatus(_Screen, "IntellisenseEvents", 5)
	_Screen.NewObject("IntellisenseEvents", "Events", "Events.prg")
EndIf
	
