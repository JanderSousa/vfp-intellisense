Set Path to (sys(5) + sys(2003)) additive

If !PemStatus(_screen, "vfp_intellisense", 5)
	_screen.NewObject("vfp_intellisense", "EventsControl", "EventsControl.prg")
EndIf