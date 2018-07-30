Module Opcodes
    Dim table As New List(Of Assembled)
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



    End Sub
    Function hexToBin(str As String) As String
        Return String.Join(String.Empty, str.[Select](Function(c) Convert.ToString(Convert.ToInt32(c.ToString(), 16), 2).PadLeft(4, "0"c)))
    End Function
End Module
