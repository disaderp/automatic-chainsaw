Module Opcodes
    Dim table As New List(Of Assembled)
    Function Find(match As Instr) As Assembled
        For Each ins In table
            If ins.instr.type = match.type And chkParams(ins.instr, match) Then
                Return ins
            End If
        Next
        Return Nothing
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
    Function chkParams(orig As Instr, match As Instr) As Boolean
        For i As Integer = 0 To 1
            If orig.pars(i).isAbs And Not match.pars(i).isAbs Then
                Return False
            End If
            If orig.pars(i).isVal And Not match.pars(i).isVal Then
                Return False
            End If
            If orig.pars(i).isAddress And Not match.pars(i).isAddress Then
                Return False
            End If
            If orig.pars(i).isReg And Not match.pars(i).isReg Then
                Return False
            End If
        Next
        Return True
    End Function
    Sub gen()
        Dim ins As Assembled

        '''' Transfer instructions

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "NOP"
        ins.opcode = hexToBin("0")
        ins.size = 1
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "SFC"
        ins.opcode = hexToBin("1")
        ins.size = 2
        ins.instr.pars(0).isVal = True
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "CFF"
        ins.opcode = hexToBin("2")
        ins.size = 1
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "COF"
        ins.opcode = hexToBin("3")
        ins.size = 1
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "CZF"
        ins.opcode = hexToBin("4")
        ins.size = 1
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "CBP"
        ins.opcode = hexToBin("2D")
        ins.size = 1
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "CPC"
        ins.opcode = hexToBin("2E")
        ins.size = 1
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "MOV"
        ins.opcode = hexToBin("5")
        ins.instr.pars(0).isAddress = True
        ins.instr.pars(1).isReg = True
        ins.size = 3
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "MOV"
        ins.opcode = hexToBin("6")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(1).isAddress = True
        ins.size = 3
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "MOV"
        ins.opcode = hexToBin("7")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(1).isReg = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "MOV"
        ins.opcode = hexToBin("8")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(1).isVal = True
        ins.size = 3
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "MOV"
        ins.opcode = hexToBin("2A")
        ins.instr.pars(0).isAbs = True
        ins.instr.pars(1).isReg = True
        ins.size = 3
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "MOV"
        ins.opcode = hexToBin("2B")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(1).isAbs = True
        ins.size = 3
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "LEA"
        ins.opcode = hexToBin("27")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(1).isReg = True
        ins.instr.pars(1).isAddress = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "LEA"
        ins.opcode = hexToBin("2C")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(0).isAddress = True
        ins.instr.pars(1).isReg = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "LEA"
        ins.opcode = hexToBin("2F")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(1).isReg = True
        ins.instr.pars(1).isAbs = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "LEA"
        ins.opcode = hexToBin("30")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(0).isAbs = True
        ins.instr.pars(1).isReg = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "POP"
        ins.opcode = hexToBin("9")
        ins.instr.pars(0).isReg = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "OUT"
        ins.opcode = hexToBin("A")
        ins.size = 1
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "IN"
        ins.opcode = hexToBin("28")
        ins.size = 1
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "XCH"
        ins.opcode = hexToBin("29")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(1).isReg = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "PUSH"
        ins.opcode = hexToBin("B")
        ins.instr.pars(0).isReg = True
        ins.size = 2
        table.Add(ins)

        '''' Arithmetic instructions

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "ADD"
        ins.opcode = hexToBin("C")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(1).isReg = True
        ins.size = 2
        table.Add(ins)
        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "ADC"
        ins.opcode = hexToBin("D")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(1).isReg = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "SUB"
        ins.opcode = hexToBin("E")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(1).isReg = True
        ins.size = 2
        table.Add(ins)
        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "SUC"
        ins.opcode = hexToBin("F")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(1).isReg = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "MUL8"
        ins.opcode = hexToBin("10")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(1).isReg = True
        ins.size = 2
        table.Add(ins)
        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "MUL6"
        ins.opcode = hexToBin("11")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(1).isReg = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "DIV8"
        ins.opcode = hexToBin("12")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(1).isReg = True
        ins.size = 2
        table.Add(ins)
        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "DIV6"
        ins.opcode = hexToBin("13")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(1).isReg = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "CMP"
        ins.opcode = hexToBin("14")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(1).isReg = True
        ins.size = 2
        table.Add(ins)

        '''' Logic instructions 

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "AND"
        ins.opcode = hexToBin("15")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(1).isReg = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "NEG"
        ins.opcode = hexToBin("16")
        ins.instr.pars(0).isReg = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "NOT"
        ins.opcode = hexToBin("17")
        ins.instr.pars(0).isReg = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "OR"
        ins.opcode = hexToBin("18")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(1).isReg = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "SHL"
        ins.opcode = hexToBin("19")
        ins.instr.pars(0).isReg = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "SHR"
        ins.opcode = hexToBin("1A")
        ins.instr.pars(0).isReg = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "XOR"
        ins.opcode = hexToBin("1B")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(1).isReg = True
        ins.size = 2
        table.Add(ins)


        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "TEST"
        ins.opcode = hexToBin("1C")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(1).isReg = True
        ins.size = 2
        table.Add(ins)

        '''' Jump instructions 

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "INT"
        ins.opcode = hexToBin("1D")
        ins.instr.pars(0).isVal = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "CALL"
        ins.opcode = hexToBin("1E")
        ins.instr.pars(0).isAddress = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "RET"
        ins.opcode = hexToBin("1F")
        ins.size = 1
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "JMP"
        ins.opcode = hexToBin("20")
        ins.instr.pars(0).isAddress = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "JMP"
        ins.opcode = hexToBin("31")
        ins.instr.pars(0).isAbs = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "JMP"
        ins.opcode = hexToBin("32")
        ins.instr.pars(0).isReg = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "JMP"
        ins.opcode = hexToBin("33")
        ins.instr.pars(0).isReg = True
        ins.instr.pars(0).isAbs = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "JC"
        ins.opcode = hexToBin("21")
        ins.instr.pars(0).isAddress = True
        ins.size = 2
        table.Add(ins)
        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "JNC"
        ins.opcode = hexToBin("22")
        ins.instr.pars(0).isAddress = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "JZ"
        ins.opcode = hexToBin("23")
        ins.instr.pars(0).isAddress = True
        ins.size = 2
        table.Add(ins)
        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "JNZ"
        ins.opcode = hexToBin("24")
        ins.instr.pars(0).isAddress = True
        ins.size = 2
        table.Add(ins)

        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "JO"
        ins.opcode = hexToBin("25")
        ins.instr.pars(0).isAddress = True
        ins.size = 2
        table.Add(ins)
        ins = New Assembled
        ins.instr.init()
        ins.instr.type = "JNO"
        ins.opcode = hexToBin("26")
        ins.instr.pars(0).isAddress = True
        ins.size = 2
        table.Add(ins)

    End Sub
    Function hexToBin(str As String) As String
        Return String.Join(String.Empty, str.[Select](Function(c) Convert.ToString(Convert.ToInt32(c.ToString(), 16), 2).PadLeft(4, "0"c)))
    End Function
End Module
