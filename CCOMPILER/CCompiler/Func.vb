Module Func
	Function StripWhites(t() As String) As String
		Dim program As String = ""
		For Each line In t
			line = line.Trim()
			If line.StartsWith("//") Or line = "" Then
				Continue For
			End If
			program += line
		Next
		Return program
	End Function
	Function analyze(t As String)

	End Function
End Module
