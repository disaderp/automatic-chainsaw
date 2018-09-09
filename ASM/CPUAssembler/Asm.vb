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
                    current.pars(0).val = mn(0).Substring(1)
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
                        current.pars(j).isAddress = True
                        current.pars(j).val = skipFirstandLast(pars(j))
                    End If
                    If isReg(current.pars(j).val) Then
                        current.pars(j).isReg = True
                    End If
                    If current.pars(j).val.Contains(".") Then
                        current.pars(j).isLabel = True
                    End If
                Next
            ElseIf Not mn(0).StartsWith("'") Or mn(0) = "" Then
                Throw New Exception("syntax error in parser: Line: " + (i + 1).ToString + ". Code: " + lines(i))
            End If

            If mn(0).StartsWith("'") Or mn(0) = "" Then
                current.type = "COMMENT"
            End If
            parsed.Add(current)
        Next
        Return parsed
    End Function
    Function match(prog As List(Of Instr)) As String
        Dim code As New List(Of String)
        Dim codestr As String = ""
        Dim ic As Integer = 0
        Dim labels As New Dictionary(Of String, Integer)
        Dim context As Integer = 0
        Dim contable As New Dictionary(Of Integer, Integer)
        contable(0) = 0
        For i As Integer = 0 To prog.Count() - 1
            Dim orig As Nullable(Of Assembled) = Opcodes.Find(prog(i))
            If prog(i).type = "LABEL" Then
                labels(prog(i).pars(0).val) = ic - contable(context)
            ElseIf prog(i).type = "SUBROUTINE" Then
                labels(prog(i).pars(0).val) = ic - contable(context)
                context += 1
                contable(context) = ic
            ElseIf prog(i).type = "BINARY" Then
                code.Add(prog(i).pars(0).val)
                ic += 1
            ElseIf Not orig.Value.opcode Is Nothing Then
                code.Add(orig.Value.opcode)
                If orig.Value.size = 2 Then
                    If prog(i).pars(1).val Is Nothing Then
                        code.Add(prepareParam(prog(i).pars(0)))
                    Else
                        code.Add(prepareParam(prog(i).pars(1)) + prepareParam(prog(i).pars(0)))
                    End If
                ElseIf orig.Value.size = 3 Then
                    code.Add(prepareParam(prog(i).pars(0)))
                    code.Add(prepareParam(prog(i).pars(1)))
                End If
                ic += orig.Value.size
            ElseIf Not prog(i).type = "COMMENT" Then
                Throw New Exception("syntax error in matcher: Line: " + (i + 1).ToString + ". Code: " + prog(i).type)
            End If
        Next
        For i As Integer = 0 To code.Count - 1
            If code(i).StartsWith(".") Then
                If Not labels.ContainsKey(code(i)) Then
                    Throw New Exception("error in label dictionary: Label not found: " + code(i))
                End If
                codestr += Trail16(Convert.ToString(labels(code(i)), 2))
            Else
                    codestr += Trail16(code(i))
            End If
        Next
        Return codestr
    End Function
    Function prepareParam(par As Param) As String
        If par.isReg Then
            Return regToBin(par.val)
        Else
            Return par.val
        End If
    End Function


    Sub Main(args As String())
        Console.WriteLine(vbNewLine + "automatic-chainsawxCPUAssembler by Disa" + vbNewLine)
        Opcodes.gen()
        Try
            If args.Count() = 0 Then
                Console.WriteLine("###Usage: <param> <output filename>" + vbNewLine + "###Params:" + vbNewLine &
                                "-bin <input filename> - writes binary file:" + vbNewLine &
                                "-ram <input filename> - prints in RAM Verilog format" + vbNewLine &
                                "-plain - prints 0s and 1s")
            ElseIf (args(0) = "-bin") Then
                Dim d As Byte() = StrToBin(match(parse(File.ReadAllText(args(2)))))
                File.WriteAllBytes(args(1), d)
            ElseIf (args(0) = "-ram") Then
                Dim d As String = toRAM(match(parse(File.ReadAllText(args(2)))))
                'Console.WriteLine(d)
                File.WriteAllText(args(1), d)
            ElseIf (args(0) = "-plain") Then
				Console.WriteLine(match(parse(File.ReadAllText(args(1)))))
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
            ReDim pars(1)
            pars(0) = New Param
            pars(1) = New Param
            pars(0).isLabel = False
            pars(0).isReg = False
            pars(0).isVal = False
            pars(0).isAbs = False
            pars(0).isAddress = False
            pars(1).isLabel = False
            pars(1).isReg = False
            pars(1).isVal = False
            pars(1).isAbs = False
            pars(1).isAddress = False
        End Sub
    End Structure
    Structure Param
        Dim isLabel As Boolean
        Dim isReg As Boolean
        Dim isVal As Boolean
        Dim isAbs As Boolean
        Dim isAddress As Boolean
        Dim val As String
    End Structure
    Structure Assembled
        Dim instr As Instr
        Dim opcode As String
        Dim size As Integer
    End Structure
End Module
