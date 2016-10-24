Module Compiler

	Sub Main(args As String())
		Console.WriteLine(Func.StripWhites(System.IO.File.ReadAllLines(args(0))))
	End Sub

End Module
