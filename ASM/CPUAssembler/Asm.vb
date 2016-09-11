Imports System.IO

Module Asm
	Function Trail16(str As String) As String
		For i As Integer = 0 To 15 - str.Length()
			str = "0" + str
		Next
		Return str
	End Function
	'Function ReplaceFirst(original As String, oldValue As String, newValue As String) As String
	'	Dim loc As Integer = original.IndexOf(oldValue)
	'	If loc < 0 Then
	'		Return original
	'	End If
	'	Return original.Remove(loc, oldValue.Length).Insert(loc, newValue)
	'End Function

	'Function AddTrailing2(num As String)
	'	Dim out As String = ""
	'	For i As Integer = num.Length To 1
	'		out += "0"
	'	Next
	'	out += num
	'	Return out
	'End Function
	Function assemble(ByVal asm As String) As String
		Dim code As String = ""
		Dim lines As String() = asm.Split(vbNewLine)
		Dim ic As Integer = 0
		Dim labels As New Dictionary(Of String, Integer)
		For i As Integer = 0 To lines.Count() - 1
			Dim mn As String = lines(i).ToUpper().Trim().Replace(vbTab, " ")
			If mn.StartsWith(".") Then
				labels(mn) = ic
				ic -= 1
			ElseIf mn.StartsWith("NOP") Then
				code += Trail16("0")
			ElseIf mn.StartsWith("SFC") Then
				code += Trail16("1") + Trail16(mn.Remove(0, 4)(0))
				ic += 1
			ElseIf mn.StartsWith("CFF") Then
				code += Trail16("10")
			ElseIf mn.StartsWith("CFF") Then
				code += Trail16("11")
			ElseIf mn.StartsWith("CFF") Then
				code += Trail16("100")
			ElseIf mn.StartsWith("MOV [") Then
				code += Trail16("101")
				Dim params As String() = mn.Remove(0, 5).Split(",")
				params(0) = params(0).Remove(params(0).Length - 1)
				code += Trail16(params(0))
				If params(1) = "AX" Then
					code += Trail16("00")
				ElseIf params(1) = "BX" Then
					code += Trail16("01")
				ElseIf params(1) = "CX" Then
					code += Trail16("10")
				ElseIf params(1) = "DX" Then
					code += Trail16("11")
				End If
				ic += 2
			ElseIf mn.Contains("[") And mn.Contains("MOV") Then
				code += Trail16("110")
				Dim params As String() = mn.Remove(0, 4).Split(",")
				params(1) = params(1).Remove(params(1).Length - 1).Remove(0, 1)
				Dim regs As String
				If params(0) = "AX" Then
					code += Trail16("00")
				ElseIf params(0) = "BX" Then
					code += Trail16("01")
				ElseIf params(0) = "CX" Then
					code += Trail16("10")
				ElseIf params(0) = "DX" Then
					code += Trail16("11")
				End If
				code += Trail16(params(1))
				ic += 2
			ElseIf mn.Contains("(") And mn.Contains("MOV") Then
				code += Trail16("1000")
				Dim params As String() = mn.Remove(0, 4).Split(",")
				params(1) = params(1).Remove(params(1).Length - 1).Remove(0, 1)
				If params(0) = "AX" Then
					code += Trail16("00")
				ElseIf params(0) = "BX" Then
					code += Trail16("01")
				ElseIf params(0) = "CX" Then
					code += Trail16("10")
				ElseIf params(0) = "DX" Then
					code += Trail16("11")
				End If
				code += Trail16(params(1))
				ic += 2
			ElseIf mn.StartsWith("MOV") Then
				code += Trail16("111")
				Dim params As String() = mn.Remove(0, 4).Split(",")
				Dim regs As String
				If params(0) = "AX" Then
					regs = "00"
				ElseIf params(0) = "BX" Then
					regs = "01"
				ElseIf params(0) = "CX" Then
					regs = "10"
				ElseIf params(0) = "DX" Then
					regs = "11"
				End If
				If params(1) = "AX" Then
					regs = Trail16(regs + "00")
				ElseIf params(1) = "BX" Then
					regs = Trail16(regs + "01")
				ElseIf params(1) = "CX" Then
					regs = Trail16(regs + "10")
				ElseIf params(1) = "DX" Then
					regs = Trail16(regs + "11")
				End If
				code += regs
				ic += 1
			ElseIf mn.StartsWith("LEA") Then
				code += Trail16("100111")
				Dim params As String() = mn.Remove(0, 4).Split(",")
				Dim regs As String
				If params(0) = "AX" Then
					regs = "00"
				ElseIf params(0) = "BX" Then
					regs = "01"
				ElseIf params(0) = "CX" Then
					regs = "10"
				ElseIf params(0) = "DX" Then
					regs = "11"
				End If
				If params(1) = "AX" Then
					regs = Trail16(regs + "00")
				ElseIf params(1) = "BX" Then
					regs = Trail16(regs + "01")
				ElseIf params(1) = "CX" Then
					regs = Trail16(regs + "10")
				ElseIf params(1) = "DX" Then
					regs = Trail16(regs + "11")
				End If
				code += regs
				ic += 1
			ElseIf mn.StartsWith("POP") Then
				code += Trail16("1001")
				Dim a As String = mn.Remove(0, 4)
				If a = "AX" Then
					code += Trail16("00")
				ElseIf a = "BX" Then
					code += Trail16("01")
				ElseIf a = "CX" Then
					code += Trail16("10")
				ElseIf a = "DX" Then
					code += Trail16("11")
				End If
				ic += 1
			ElseIf mn.StartsWith("PUSH") Then
				code += Trail16("1011")
				Dim a As String = mn.Remove(0, 5)
				If a = "AX" Then
					code += Trail16("00")
				ElseIf a = "BX" Then
					code += Trail16("01")
				ElseIf a = "CX" Then
					code += Trail16("10")
				ElseIf a = "DX" Then
					code += Trail16("11")
				End If
				ic += 1
			ElseIf mn.StartsWith("XCH") Then
				code += Trail16("101001")
				Dim params As String() = mn.Remove(0, 4).Split(",")
				Dim regs As String
				If params(0) = "AX" Then
					regs = "00"
				ElseIf params(0) = "BX" Then
					regs = "01"
				ElseIf params(0) = "CX" Then
					regs = "10"
				ElseIf params(0) = "DX" Then
					regs = "11"
				End If
				If params(1) = "AX" Then
					regs = Trail16(regs + "00")
				ElseIf params(1) = "BX" Then
					regs = Trail16(regs + "01")
				ElseIf params(1) = "CX" Then
					regs = Trail16(regs + "10")
				ElseIf params(1) = "DX" Then
					regs = Trail16(regs + "11")
				End If
				code += regs
				ic += 1
			ElseIf mn.StartsWith("OUT") Then
				code += Trail16("1010")
			ElseIf mn.StartsWith("IN") Then
				code += Trail16("101000")


			ElseIf mn.StartsWith("ADD") Then
				code += Trail16("1100")
			ElseIf mn.StartsWith("ADC") Then
				code += Trail16("1101")
			ElseIf mn.StartsWith("SUB") Then
				code += Trail16("1110")
			ElseIf mn.StartsWith("SUC") Then
				code += Trail16("1111")
			ElseIf mn.StartsWith("MUL8") Then
				code += Trail16("10000")
			ElseIf mn.StartsWith("MUL6") Then
				code += Trail16("10001")
			ElseIf mn.StartsWith("DIV8") Then
				code += Trail16("10010")
			ElseIf mn.StartsWith("DIV6") Then
				code += Trail16("10011")
			ElseIf mn.StartsWith("CMP") Then
				code += Trail16("10100")

			ElseIf mn.StartsWith("AND") Then
				code += Trail16("10101")
			ElseIf mn.StartsWith("NEG") Then
				code += Trail16("10110")
			ElseIf mn.StartsWith("NOT") Then
				code += Trail16("10111")
			ElseIf mn.StartsWith("OR") Then
				code += Trail16("11000")
			ElseIf mn.StartsWith("SHL") Then
				code += Trail16("11001")
			ElseIf mn.StartsWith("SHR") Then
				code += Trail16("11010")
			ElseIf mn.StartsWith("XOR") Then
				code += Trail16("11011")
			ElseIf mn.StartsWith("TEST") Then
				code += Trail16("11100")
				Dim params As String() = mn.Remove(0, 4).Split(",")
				Dim regs As String
				If params(0) = "AX" Then
					regs = "00"
				ElseIf params(0) = "BX" Then
					regs = "01"
				ElseIf params(0) = "CX" Then
					regs = "10"
				ElseIf params(0) = "DX" Then
					regs = "11"
				End If
				If params(1) = "AX" Then
					regs = Trail16(regs + "00")
				ElseIf params(1) = "BX" Then
					regs = Trail16(regs + "01")
				ElseIf params(1) = "CX" Then
					regs = Trail16(regs + "10")
				ElseIf params(1) = "DX" Then
					regs = Trail16(regs + "11")
				End If
				code += regs
				ic += 1

			ElseIf mn.StartsWith("INT") Then
				code += Trail16("11101")
				code += Trail16(mn.Remove(0, 4))
				ic += 1
			ElseIf mn.StartsWith("CALL") Then
				code += Trail16("11110")
				code += Trail16(mn.Remove(0, 5))
				ic += 1
			ElseIf mn.StartsWith("RET") Then
				code += Trail16("11111")

			ElseIf mn.StartsWith("JMP") Then
				code += Trail16("100000") + "," + mn.Remove(0, 4) + ","
				ic += 1
			ElseIf mn.StartsWith("JC") Then
				code += Trail16("100001,") + "," + +mn.Remove(0, 3) + ","
				ic += 1
			ElseIf mn.StartsWith("JNC") Then
				code += Trail16("100010,") + "," + +mn.Remove(0, 4) + ","
				ic += 1
			ElseIf mn.StartsWith("JZ") Then
				code += Trail16("100011,") + "," + +mn.Remove(0, 3) + ","
				ic += 1
			ElseIf mn.StartsWith("JNZ") Then
				code += Trail16("100100,") + "," + +mn.Remove(0, 4) + ","
				ic += 1
			ElseIf mn.StartsWith("JO") Then
				code += Trail16("100101,") + "," + +mn.Remove(0, 3) + ","
				ic += 1
			ElseIf mn.StartsWith("JNO") Then
				code += Trail16("100110,") + "," + +mn.Remove(0, 4) + ","
				ic += 1
			ElseIf mn = "" Then
				ic -= 1
			Else
				code += "ZZ "
				Console.WriteLine("not implemented line: " + i + 1 + " line: " + lines(i))
				Console.ReadLine()
				Environment.Exit(1)
				Continue For
			End If
			ic += 1
		Next
		Dim lab As String() = code.Split(",")
		For i As Integer = 1 To lab.Count() - 1 Step 2
			Dim add As String = ""
			Try
				add = Trail16(Convert.ToString(labels(lab(i)), 2))
			Catch
				Console.WriteLine("error in label dictionary")
				Console.ReadLine()
				Environment.Exit(2)
			End Try
			code = code.Replace("," + lab(i) + ",", add)
		Next
		Return code
	End Function
	Sub Main(args As String())
		Try
			Console.WriteLine(assemble(File.ReadAllText(args(0))))
		Catch ex As Exception
			Console.WriteLine(ex.ToString)
		End Try
	End Sub

End Module
