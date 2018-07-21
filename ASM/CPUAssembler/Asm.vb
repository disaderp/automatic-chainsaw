Imports System.IO

Module Asm
	Function Trail16(str As String) As String
		For i As Integer = 0 To 15 - str.Length()
			str = "0" + str
		Next
		Return str
	End Function
	Function StrToBin(str As String) As Byte()
		Dim nBytes As Integer = str.Length / 8
		Dim bytesAsStrings = Enumerable.Range(0, nBytes).[Select](Function(i) str.Substring(8 * i, 8))
		Dim bytes As Byte() = bytesAsStrings.[Select](Function(s) Convert.ToByte(s, 2)).ToArray()
		Return bytes
	End Function
    Function toRAM(str As String) As String
        Dim ram As String = ""
        For i As Integer = 0 To (str.Length() / 16) - 1
            ram += "ram[" & i & "] <= 16'b" + str.Substring(i * 16, 16) + ";" + vbNewLine
        Next
        Return ram
    End Function
    Function skipFirstandLast(str As String) As String
        Return str.Substring(1, str.Length - 2)
    End Function
    Function isReg(str As String) As Boolean
        If regToBin(str) = "X" Then
            Return False
        Else Return True
        End If
    End Function
    Function regToBin(str As String) As String
        If str = "AX" Then
            Return "00"
        ElseIf str = "BX" Then
            Return "01"
        ElseIf str = "CX" Then
            Return "10"
        ElseIf str = "DX" Then
            Return "11"
        Else Return "X"
        End If
    End Function
    Function parse(str As String) As List(Of Instr)
        Dim lines As String() = str.Replace(vbCr, "").Split(vbLf)
        Dim parsed As New List(Of Instr)

        For i As Integer = 0 To lines.Count() - 1
            Dim mn As String() = lines(i).ToUpper().Trim().Replace(vbTab, " ").Split(" ")
            Dim current As New Instr
            current.init()
            If mn.Count() = 1 Then
                current.pars(0).val = mn(0)
                If mn(0).StartsWith(".") Then
                    current.type = "LABEL"
                ElseIf mn(0).StartsWith(":") Then
                    current.type = "SUBROUTINE"
                ElseIf mn(0).StartsWith("X") Then
                    current.type = "BINARY"
                Else
                    current.type = mn(0)
                End If
            ElseIf mn.Count() = 2 Then
                current.type = mn(0)
                Dim pars As String() = mn(1).Split(",")
                For j As Integer = 0 To pars.Count - 1
                    current.pars(j).val = pars(j)
                    If pars(j).Contains("(") Then
                        current.pars(j).isVal = True
                        current.pars(j).val = skipFirstandLast(pars(j))
                    ElseIf pars(j).Contains("<") Then
                        current.pars(j).isAbs = True
                        current.pars(j).val = skipFirstandLast(pars(j))
                    ElseIf pars(j).Contains("[") Then
                        current.pars(j).isAbs = False
                        current.pars(j).val = skipFirstandLast(pars(j))
                    End If
                    If isReg(current.pars(j).val) Then
                        current.pars(j).isReg = True
                    End If
                    If current.pars(j).val.Contains(".") Then
                        current.pars(j).isLabel = True
                    End If
                Next
            Else
                Throw New Exception("syntax error")
            End If
            parsed.Add(current)
        Next
        Return parsed
    End Function

    Function assemble(ByVal asm As String) As String
		Dim code As String = ""
		Dim lines As String() = asm.Replace(vbCr, "").Split(vbLf)
		Dim ic As Integer = 0
		Dim labels As New Dictionary(Of String, Integer)
		Dim context As Integer = 0
		Dim contable As New Dictionary(Of Integer, Integer)
		contable(0) = 0
		For i As Integer = 0 To lines.Count() - 1
			Dim mn As String = lines(i).ToUpper().Trim().Replace(vbTab, " ")
            If mn.StartsWith(".") Then
                labels(mn) = ic - contable(context)
                ic -= 1
            ElseIf mn.StartsWith(":") Then
                labels(mn) = ic - contable(context)
                context += 1
                contable(context) = ic
                ic -= 1
            ElseIf mn.StartsWith("'") Then
                ic -= 1
            ElseIf mn.StartsWith("X[") Then
                code += Trail16(mn.Substring(2).Replace("]", ""))
            ElseIf mn.StartsWith("X") Then
                code += Trail16(mn.Substring(1))
            ElseIf mn.StartsWith("NOP") Then
				code += Trail16("0")
			ElseIf mn.StartsWith("SFC") Then
				code += Trail16("1") + Trail16(mn.Remove(0, 4)(0))
				ic += 1
			ElseIf mn.StartsWith("CFF") Then
				code += Trail16("10")
			ElseIf mn.StartsWith("COF") Then
				code += Trail16("11")
			ElseIf mn.StartsWith("CZF") Then
				code += Trail16("100")
			ElseIf mn.StartsWith("CBP") Then
				code += Trail16("101101")
			ElseIf mn.StartsWith("CPC") Then
				code += Trail16("101110")
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
			ElseIf mn.StartsWith("MOV <") Then
				code += Trail16("101010")
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
			ElseIf mn.Contains("<") And mn.Contains("MOV") Then
				code += Trail16("101011")
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
			ElseIf mn.StartsWith("LEA [") Then
				code += Trail16("101100")
				Dim params As String() = mn.Remove(0, 5).Replace("]", "").Split(",")
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
			ElseIf mn.StartsWith("LEA <") Then
				code += Trail16("110000")
				Dim params As String() = mn.Remove(0, 5).Replace(">", "").Split(",")
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
			ElseIf mn.StartsWith("LEA") And mn.Contains("[") Then
				code += Trail16("100111")
				Dim params As String() = mn.Remove(0, 4).Replace("[", "").Replace("]", "").Split(",")
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
			ElseIf mn.StartsWith("LEA") And mn.Contains("<") Then
				code += Trail16("101111")
				Dim params As String() = mn.Remove(0, 4).Replace("<", "").Replace(">", "").Split(",")
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
			ElseIf mn.StartsWith("ADC") Then
				code += Trail16("1101")
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
			ElseIf mn.StartsWith("SUB") Then
				code += Trail16("1110")
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
			ElseIf mn.StartsWith("SUC") Then
				code += Trail16("1111")
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
			ElseIf mn.StartsWith("MUL8") Then
				code += Trail16("10000")
				Dim params As String() = mn.Remove(0, 5).Split(",")
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
			ElseIf mn.StartsWith("MUL6") Then
				code += Trail16("10001")
				Dim params As String() = mn.Remove(0, 5).Split(",")
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
			ElseIf mn.StartsWith("DIV8") Then
				code += Trail16("10010")
				Dim params As String() = mn.Remove(0, 5).Split(",")
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
			ElseIf mn.StartsWith("DIV6") Then
				code += Trail16("10011")
				Dim params As String() = mn.Remove(0, 5).Split(",")
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
			ElseIf mn.StartsWith("CMP") Then
				code += Trail16("10100")
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


			ElseIf mn.StartsWith("AND") Then
				code += Trail16("10101")
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
			ElseIf mn.StartsWith("NEG") Then
				code += Trail16("10110")
				Dim params As String = mn.Remove(0, 4)
				Dim regs As String
				If params = "AX" Then
					regs = "00"
				ElseIf params = "BX" Then
					regs = "01"
				ElseIf params = "CX" Then
					regs = "10"
				ElseIf params = "DX" Then
					regs = "11"
				End If
				code += regs
				ic += 1
			ElseIf mn.StartsWith("NOT") Then
				code += Trail16("10111")
				Dim params As String = mn.Remove(0, 4)
				Dim regs As String
				If params = "AX" Then
					regs = "00"
				ElseIf params = "BX" Then
					regs = "01"
				ElseIf params = "CX" Then
					regs = "10"
				ElseIf params = "DX" Then
					regs = "11"
				End If
				code += regs
				ic += 1
			ElseIf mn.StartsWith("OR") Then
				code += Trail16("11000")
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
			ElseIf mn.StartsWith("SHL") Then
				code += Trail16("11001")
				Dim params As String = mn.Remove(0, 4)
				Dim regs As String
				If params = "AX" Then
					regs = "00"
				ElseIf params = "BX" Then
					regs = "01"
				ElseIf params = "CX" Then
					regs = "10"
				ElseIf params = "DX" Then
					regs = "11"
				End If
				code += regs
				ic += 1
			ElseIf mn.StartsWith("SHR") Then
				code += Trail16("11010")
				Dim params As String = mn.Remove(0, 4)
				Dim regs As String
				If params = "AX" Then
					regs = "00"
				ElseIf params = "BX" Then
					regs = "01"
				ElseIf params = "CX" Then
					regs = "10"
				ElseIf params = "DX" Then
					regs = "11"
				End If
				code += regs
				ic += 1
			ElseIf mn.StartsWith("XOR") Then
				code += Trail16("11011")
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
			ElseIf mn.StartsWith("TEST") Then
				code += Trail16("11100")
				Dim params As String() = mn.Remove(0, 5).Split(",")
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
			ElseIf mn.StartsWith("CALL [") Then
				code += Trail16("11110")
				code += Trail16(mn.Substring(6).Replace("]", ""))
				ic += 1
			ElseIf mn.StartsWith("CALL") Then
				code += Trail16("11110") + "," + mn.Remove(0, 5) + ","
				ic += 1
			ElseIf mn.StartsWith("RET") Then
				code += Trail16("11111")
				context -= 1
			ElseIf mn.StartsWith("JMP [" & mn.Contains("X")) Then
				code += Trail16("110010")
				Dim params As String = mn.Remove(0, 5).Replace("]", "")
				Dim regs As String
				If params = "AX" Then
					regs = Trail16(regs + "00")
				ElseIf params = "BX" Then
					regs = Trail16(regs + "01")
				ElseIf params = "CX" Then
					regs = Trail16(regs + "10")
				ElseIf params = "DX" Then
					regs = Trail16(regs + "11")
				End If
				code += regs
				ic += 1
			ElseIf mn.StartsWith("JMP <" & mn.Contains("X")) Then
				code += Trail16("110011")
                Dim params As String = mn.Remove(0, 5).Replace(">", "")
                Dim regs As String
				If params = "AX" Then
					regs = Trail16(regs + "00")
				ElseIf params = "BX" Then
					regs = Trail16(regs + "01")
				ElseIf params = "CX" Then
					regs = Trail16(regs + "10")
				ElseIf params = "DX" Then
					regs = Trail16(regs + "11")
				End If
				code += regs
				ic += 1
			ElseIf mn.StartsWith("JMP [") Then
				code += Trail16("100000")
				code += Trail16(mn.Remove(0, 5).Replace("]", ""))
				ic += 1
			ElseIf mn.StartsWith("JMP <") Then
				code += Trail16("110001")
				code += Trail16(mn.Remove(0, 5).Replace(">", ""))
				ic += 1
			ElseIf mn.StartsWith("JMP") Then
				code += Trail16("100000") + "," + mn.Remove(0, 4) + ","
				ic += 1
			ElseIf mn.StartsWith("JC") Then
				code += Trail16("100001") + "," + mn.Remove(0, 3) + ","
				ic += 1
			ElseIf mn.StartsWith("JNC") Then
				code += Trail16("100010") + "," + mn.Remove(0, 4) + ","
				ic += 1
			ElseIf mn.StartsWith("JZ") Then
				code += Trail16("100011") + "," + mn.Remove(0, 3) + ","
				ic += 1
			ElseIf mn.StartsWith("JNZ") Then
				code += Trail16("100100") + "," + mn.Remove(0, 4) + ","
				ic += 1
			ElseIf mn.StartsWith("JO") Then
				code += Trail16("100101") + "," + mn.Remove(0, 3) + ","
				ic += 1
			ElseIf mn.StartsWith("JNO") Then
				code += Trail16("100110") + "," + mn.Remove(0, 4) + ","
				ic += 1
			ElseIf mn = "" Then
				ic -= 1
			Else
				code += "ZZ "
				Console.WriteLine("not implemented line: " & i + 1 & " line: " + lines(i))
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
                'Environment.Exit(2)
            End Try
			code = code.Replace("," + lab(i) + ",", add)
		Next
		Return code
	End Function
	Sub Main(args As String())
		Console.WriteLine(vbNewLine + "xCPUAssembler by Disa" + vbNewLine)
		Try
            If args.Count() = 0 Then
                Console.WriteLine("###Usage: <param> <output filename>" + vbNewLine + "###Params:" + vbNewLine &
                            "-bin <input filename> - writes binary file:" + vbNewLine &
                            "-ram <input filename> - prints in RAM Verilog format" + vbNewLine &
                            "-plain - prints 0s and 1s")
            ElseIf (args(0) = "-bin") Then
                Dim d As Byte() = StrToBin(assemble(File.ReadAllText(args(2))))
                File.WriteAllBytes(args(1), d)
            ElseIf (args(0) = "-ram") Then
                parse(File.ReadAllText(args(2)))
                Dim d As String = toRAM(assemble(File.ReadAllText(args(2))))
                Console.WriteLine(d)
                File.WriteAllText(args(1), d)
			ElseIf (args(0) = "-plain") Then
				Console.WriteLine(assemble(File.ReadAllText(args(1))))
			Else
				Console.WriteLine("###Usage: <param> <output filename>" + vbNewLine + "###Params:" + vbNewLine &
							"-bin <input filename> - writes binary file:" + vbNewLine &
							"-ram <input filename> - prints in RAM Verilog format" + vbNewLine &
							"-plain - prints 0s and 1s")
			End If
			Console.WriteLine("Done.")
			Environment.Exit(0)
		Catch ex As Exception
			Console.Error.WriteLine(ex.ToString)
			Environment.Exit(1)
		End Try
	End Sub


    Structure Instr
        Dim type As String
        Dim pars As Param()
        Public Sub init()
            ReDim pars(2)
            pars(0) = New Param
            pars(1) = New Param
            pars(0).isLabel = False
            pars(0).isReg = False
            pars(0).isVal = False
            pars(0).isAbs = False
            pars(1).isLabel = False
            pars(1).isReg = False
            pars(1).isVal = False
            pars(1).isAbs = False
        End Sub
    End Structure
    Structure Param
        Dim isLabel As Boolean
        Dim isReg As Boolean
        Dim isVal As Boolean
        Dim isAbs As Boolean
        Dim val As String
    End Structure
End Module
