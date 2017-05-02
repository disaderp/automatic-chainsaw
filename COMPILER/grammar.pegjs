{
  function Node(kind, extra) {
    return Object.assign({ kind }, extra);
  }

  function isDefined(val) {
    return typeof val !== 'undefined';
  }

  function cleanUp(object) {
    for (let key in object) {
      if (!object.hasOwnProperty(key)) continue;
      if (object[key] === object) continue;
      switch (typeof object[key]) {
      case 'undefined':
        if (Array.isArray(object)) object.splice(key, 1);
        else delete object[key];
        break;
      case 'object':
        if (Array.isArray(object[key])) {
          object[key].forEach(cleanUp);
          object[key] = object[key].filter(isDefined);
        } else cleanUp(object[key]);
        break;
      }
    }
  }
}

Program "program"
  = _ statements:Statement * { statements.forEach(cleanUp); return statements.filter(isDefined); }

Statement "statement"
  = ConditionalStatement
  / ConditionalLoopStatement
  / VariableDeclaration
  / AssignmentStatement
  / StatementTerminator
  / ReturnStatement
  / Comment { }
  / FunctionDefinition
  / ExpressionStatement
  / CompoundStatement

ReturnStatement "return statement"
  = "return" _ expression:Expression _ StatementTerminator { return Node('ReturnStatement', { expression }); }

ConditionalStatement "if"
  = "if" _ predicate:Expression _ statement:Statement _ elseStatement: ElseStatement ? {
      return Node('ConditionalStatement', { predicate, statement, elseStatement });
    }

ConditionalLoopStatement "while"
  = "while" _ predicate:Expression _ statement:Statement _ {
      return Node('ConditionalLoopStatement', { predicate, statement });
    }

ElseStatement "else"
  = "else" _ statement:Statement { return statement; }

FunctionCall "function call"
  = name:Identifier _ "(" _ args:ActualParameters _ ")" _ {
      return Node('FunctionCall', {
        name,
        args,
      });
    }

ArrayLookup "array lookup"
  = array:Expression _ "[" _ Expression _ "]"

ActualParameters
  = head:Expression ArgumentSeparator tail:ActualParameters { return [head].concat(tail); }
    / expression:Expression { return [expression]; }
    / _ { return []; }

ExpressionStatement "expression statement"
  = expression:Expression _ StatementTerminator { return Node('ExpressionStatement', { expression }); }

CompoundStatement "compound statement"
  = _ "{" _ inner:Statement * _ "}" _ { return inner.length ? inner : Node('EmptyStatement'); }

FunctionDefinition "function definition"
  = convention:CallingConvention _ type:TypeSpecifier _ name:Identifier _ "(" _ args:FormalArguments _ ")" _ statement: CompoundStatement {
      return Node('FunctionDefinition', {
        convention: convention === "fastcall" ? convention : "stdcall",
        type,
        name,
        args,
        statement,
      });
    }

CallingConvention
  = "stdcall"
    / "fastcall"
    / ""

TypeSpecifier "type specifier"
  = name:Identifier _ modifiers:TypeModifier * { return Node('Type', { name, modifiers }); }

FormalArguments "formal arguments list"
  = head:FormalArgument ArgumentSeparator tail:FormalArguments { return [head].concat(tail); }
    / arg:FormalArgument { return [arg]; }
    / _ { return []; }

FormalArgument
  = type:TypeSpecifier _ name:Identifier { return Node('FormalArgument', { type, name }); }

TypeModifier
  = "*" { return Node('PointerTypeModifier'); }
    / "[" _ capacity:Integer _ "]" { return Node('ArrayTypeModifier', { capacity: capacity.value }); }

ArgumentSeparator
  = _ "," _ { }

VariableDeclaration "variable declaration"
    = type:TypeSpecifier _ name:Identifier initial:AssignmentTail? _ StatementTerminator {
      return {
        kind: 'VariableDeclaration',
        type,
        name,
        initial,
      };
    }

AssignmentTail "assignment"
  = _ "=" _ value:Expression { return value; }

AssignmentStatement
  = leftHandSide:Expression tail:AssignmentTail {
      return Node('AssignmentStatement', { leftHandSide, rightHandSide: tail });
    }

Expression
  = "(" _ leftOperand:Expression _ operator:BinaryOperator _ rightOperand:Expression _ ")" {
      return Node('BinaryOperator', { leftOperand, operator, rightOperand });
    }
    / "(" _ operator:LeftUnaryOperator _ operand:Expression _ ")" {
      return Node('UnaryOperator', { operand, operator });
    }
    / "(" _ expression:Expression _ ")" { return expression; }
    / expression:FunctionCall { return expression; }
    / expression:TerminalExpression { return expression; }

BinaryOperator "binary operator"
  = "+"
  / "-"
  / "*"
  / "/"
  / "%"
  / "&"
  / "&&"
  / "|"
  / "||"
  / "^"
  / "=="
  / "="
  / ">"
  / "<"
  / "<="
  / ">="
  / "."

LeftUnaryOperator "unary operator"
  = "+"
  / "-"
  / "*"
  / "&"
  / "~"
  / "!"

TerminalExpression
  = String
  / Integer
  / Identifier

StatementTerminator "statement terminator"
  = _ ";" _ { }

EmptyStatement
  = StatementTerminator { return Node('EmptyStatement'); }

Identifier "identifier"
  = chars: $([a-zA-Z_][a-zA-Z0-9_]*) { return Node('Identifier', {
    toString() {
      return chars;
    },
  }); }

String "string"
  = '"' inner:StringInner '"' { return Node('String', { value: inner }); }

StringInner "string data"
  = chars:([^"])* { return chars.join(''); }

Integer
  = Hexadecimal
  / Decimal

Decimal "decimal"
  = digits:([0-9]+) { return Node('Integer', { value: parseInt(digits.join(''), 10) }); }

Hexadecimal
  = "0" [Xx] nibbles:([0-9a-fA-F]+) { return Node('Integer', { value: parseInt(nibbles.join(''), 16) }); }

Comment "comment"
  = "/*" CommentInner * "*/" _ { }

CommentInner
  = ! CommentTerminator . { }

CommentTerminator
  = "*/"

_ "whitespace"
  = Comment { }
  / [ \t\n\r]* { }
