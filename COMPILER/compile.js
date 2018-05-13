let parser;
const util = require('util');
const Generator = require('./generator').Generator;

global.inspect = inspect;
function inspect(value) {
  console.log(util.inspect(value, false, null));
}

exports.compile = compile;
function compile(program) {
  const generator = Generator();
  visit(generator, program, {});
  return generator.getAssembly();
}

let callingConventions = {};
const visitors = {
  VariableDeclaration(generator, { type, name, initial }) {
    generator.data(name, typeSize(type), initial !== null ? initial.value : generator.zeros(typeSize(type)));//@TODO: add check type size (pi=314)
  },

  ConditionalStatement(generator, statement) {
    statement.id = generator.randomIdentifier();

    if (statement.predicate.kind == 'Identifier') {
      generator.op.lea(generator.r.ax, generator.l[statement.predicate]);
    } else if (statement.predicate.kind == 'Integer' || statement.predicate.kind == 'Char') {
      generator.op.mov(generator.r.ax, statement.predicate.value);
    } else {
      visitors[statement.predicate.kind](generator, statement.predicate);
    }

    generator.op.mov(generator.r.cx, 0);
    generator.op.test(generator.r.ax, generator.r.cx);
    generator.op.jz('.elseif' + statement.id);
    for (let i = 0; i < statement.statement.length; i++) {
      if (statement.statement[i].kind != null) {
        visitors[statement.statement[i].kind](generator, statement.statement[i]);
      }
    }
    generator.op.jmp('.endif' + statement.id);
    generator.label('elseif' + statement.id);
    for (let i = 0; i < statement.elseStatement.length; i++) {
      if (statement.elseStatement[i].kind != null) {
        visitors[statement.elseStatement[i].kind](generator, statement.elseStatement[i]);
      }
    }
    generator.label('endif' + statement.id);
  },

  ConditionalLoopStatement(generator, statement) {
    statement.id = generator.randomIdentifier();
    generator.label('while' + statement.id);

    if (statement.predicate.kind == 'Identifier') {
      generator.op.lea(generator.r.ax, generator.l[statement.predicate]);
    } else if (statement.predicate.kind == 'Integer' || statement.predicate.kind == 'Char') {
      generator.op.mov(generator.r.ax, statement.predicate.value);
    } else {
      visitors[statement.predicate.kind](generator, statement.predicate);
    }

    generator.op.mov(generator.r.cx, 0);
    generator.op.test(generator.r.ax, generator.r.cx);
    generator.op.jz('.endwhile' + statement.id);
    for (let i = 0; i < statement.statement.length; i++) {
      if (statement.statement[i].kind != 'Identifier') {
        visitors[statement.statement[i].kind](generator, statement.statement[i]);
      }
    }
    generator.op.jmp('.while' + statement.id);
    generator.label('endwhile' + statement.id);
  },

  AssignmentStatement(generator, statement) {
    if (statement.rightHandSide.kind == 'Identifier') {
      generator.op.lea(generator.r.ax, generator.l[statement.rightHandSide]);
      generator.op.mov(generator.l[statement.leftHandSide], generator.r.ax);
    } else if (statement.rightHandSide.kind == 'Integer' || statement.rightHandSide.kind == 'Char') {
      generator.op.mov(generator.l[statement.leftHandSide], statement.rightHandSide.value);
    } else {
      visitors[statement.rightHandSide.kind](generator, statement.rightHandSide);
      generator.op.mov(generator.l[statement.leftHandSide], generator.r.ax);
    }
  },

  ReturnStatement(generator, statement, { callingConvention }) {
    if (statement.expression.kind == 'Identifier') {
      generator.op.lea(generator.r.ax, generator.l[statement.expression]);
    } else if (statement.expression.kind == 'Integer' || statement.expression.kind == 'Char') {
      generator.op.mov(generator.r.ax, statement.expression.value);
    } else {
      visitors[statement.expression.kind](generator, statement.expression);
    }

    generator.op.pop(generator.r.dx);
    generator.op.jmp(generator.r.dx);
  },

  FunctionDefinition(generator, statement) {
    generator.label('func' + statement.name);
    let extra = { callingConvention: statement.convention };
    callingConventions[statement.name] = statement.convention;
    if (statement.convention == 'fastcall') {
      if (statement.args.length > 4) {
        throw new Error('too many args for fastcall');
      }
      let reg = 'AX';
      for (let i = 0; i < statement.args.length; i++) {
        generator.data(statement.args[i].name, typeSize(statement.args[i].type), generator.zeros(typeSize(statement.args[i].type)));
        generator.op.mov(generator.l[statement.args[i].name], reg);
        switch (reg) {
          case 'AX':
            reg = 'BX';
            break;
          case 'BX':
            reg = 'CX';
            break;
          case 'CX':
            reg = 'DX';
            break;
        }
      }
      for (let i = 0; i < statement.statement.length; i++) {
        if (statement.statement[i].kind != null) {
          visitors[statement.statement[i].kind](generator, statement.statement[i], extra);
        }
      }
    } else {
      for (let i = 0; i < statement.args.length; i++) {
        generator.op.pop(generator.r.dx);
        generator.op.mov(generator.l[statement.args[i].name], generator.r.dx);
      }
      for (let i = 0; i < statement.statement.length; i++) {
        if (statement.statement[i].kind != null) {
          visitors[statement.statement[i].kind](generator, statement.statement[i], extra);
        }
      }
    }
  },

  ExpressionStatement(generator, statement) {
    if (statement.expression.kind == 'FunctionCall') {
      if (statement.expression.name == 'print_const') {
        for (let i = 0; i < statement.expression.args[0].value.length; i++) {
          generator.db(0b11000001);
          generator.db(statement.expression.args[0].value[i]);
        }
        generator.db(0b11000001);
        generator.db(0);
        return;
      }
      generator.op.cpc();
      generator.op.push(generator.r.dx);
      statement.expression.convention = callingConventions[statement.expression.name];
      if (statement.expression.convention == 'fastcall') {
        if (statement.expression.args.length > 4) {
          throw new Error('too many args for fastcall');
        }
        let reg = 'AX';
        for (let i = 0; i < statement.expression.args.length - 1; i++) {
          if (statement.expression.args[i].kind == 'Identifier') {
            generator.op.lea(reg, generator.l[statement.expression.args[i]]);
          } else if (statement.expression.kind == 'Integer' || statement.expression.kind == 'Char') {
            generator.op.mov(reg, statement.expression.args[i].value);
          } else {
            throw new Error('do not use expression in fastcall function call');
          }
          switch (reg) {
            case 'AX':
              reg = 'BX';
              break;
            case 'BX':
              reg = 'CX';
              break;
            case 'CX':
              reg = 'DX';
              break;
          }
        }
      } else {
        for (let i = statement.expression.args.length - 1; i >= 0; i--) {
          if (statement.expression.args[i].kind == 'Identifier') {
            generator.op.lea(generator.r.dx, generator.l[statement.expression.args[i]]);
          } else if (statement.expression.args[i].kind == 'Integer' || statement.expression.args[i].kind == 'Char') {
            generator.op.mov(generator.r.dx, statement.expression.args[i].value);
          } else {
            visitors[statement.expression.args[i].kind](generator, statement.expression.args[i]);
            generator.op.mov(generator.r.dx, generator.r.ax);
          }
          generator.op.push(generator.r.dx);
        }
      }
      generator.op.jmp('.func' + statement.expression.name);
    }
  },

  BinaryOperator(generator, statement){
    if (statement.leftOperand.kind == 'Identifier') {
      generator.op.lea(generator.r.dx, generator.l[statement.leftOperand]);
      generator.op.push(generator.r.dx);
    } else if (statement.leftOperand.kind == 'Integer' || statement.leftOperand.kind == 'Char') {
      generator.op.mov(generator.r.dx, statement.leftOperand.value);
      generator.op.push(generator.r.dx);
    } else {
      visitors[statement.leftOperand.kind](generator, statement.leftOperand);
      generator.op.push(generator.r.ax);
    }

    if (statement.rightOperand.kind == 'Identifier') {
      generator.op.lea(generator.r.dx, generator.l[statement.rightOperand]);
    } else if (statement.rightOperand.kind == 'Integer' || statement.rightOperand.kind == 'Char') {
      generator.op.mov(generator.r.dx, statement.rightOperand.value);
    } else {
      visitors[statement.rightOperand.kind](generator, statement.rightOperand);
      generator.op.mov(generator.r.dx, generator.r.ax);
    }

    generator.op.pop(generator.r.ax);
    switch (statement.operator) {
      case '+':
        generator.op.add(generator.r.ax, generator.r.dx);
        break;
      case '-':
        generator.op.sub(generator.r.ax, generator.r.dx);
        break;
      case '*':
        generator.op.mul8(generator.r.ax, generator.r.dx);
        break;
      case '/':
        generator.op.div8(generator.r.ax, generator.r.dx);
        break;
      case '&':
        generator.op.and(generator.r.ax, generator.r.dx);
        break;
      case '|':
        generator.op.or(generator.r.ax, generator.r.dx);
        break;
      case '<<':
        generator.op.shl(generator.r.ax, generator.r.dx);
        break;
      case '==':
        generator.op.test(generator.r.ax, generator.r.dx);
        statement.id = generator.randomIdentifier();
        generator.op.mov(generator.r.ax, 0);
        generator.op.jnz(generator.l['.testexit' + statement.id]);
        generator.op.mov(generator.r.ax, 1);
        generator.label('testexit' + statement.id);
        break;
      case '<':
        generator.op.cmp(generator.r.ax, generator.r.dx);
        statement.id = generator.randomIdentifier();
        generator.op.mov(generator.r.ax, 0);
        generator.op.jnc(generator.l['.testexit' + statement.id]);
        generator.op.mov(generator.r.ax, 1);
        generator.label('testexit' + statement.id);
        break;
      case '>':
        generator.op.cmp(generator.r.ax, generator.r.dx);
        statement.id = generator.randomIdentifier();
        generator.op.mov(generator.r.ax, 0);
        generator.op.jno(generator.l['.testexit' + statement.id]);
        generator.op.mov(generator.r.ax, 1);
        generator.label('testexit' + statement.id);
        break;
      case '>=':
        generator.op.cmp(generator.r.ax, generator.r.dx);
        statement.id = generator.randomIdentifier();
        generator.op.mov(generator.r.ax, 0);
        generator.op.jc(generator.l['.testexit' + statement.id]);
        generator.op.mov(generator.r.ax, 1);
        generator.label('testexit' + statement.id);
        break;
      case '<=':
        generator.op.cmp(generator.r.ax, generator.r.dx);
        statement.id = generator.randomIdentifier();
        generator.op.mov(generator.r.ax, 0);
        generator.op.jo(generator.l['.testexit' + statement.id]);
        generator.op.mov(generator.r.ax, 1);
        generator.label('testexit' + statement.id);
        break;
      default:
        throw new Error('not implemented operator');
    }
  },

  UnaryOperator(generator, statement){
    if (statement.operand.kind === 'Identifier') {
      generator.op.lea(generator.r.ax, generator.l[statement.operand]);
    } else if (statement.operand.kind === 'Integer' || statement.operand.kind === 'Char') {
      generator.op.mov(generator.r.ax, statement.operand.value);
    } else {
      visitors[statement.operand.kind](generator, statement.operand);
      generator.op.push(generator.r.ax);
    }

    switch (statement.operator) {
      case '!':
        generator.op.not(generator.r.ax);
        break;
      case '~':
        generator.op.neg(generator.r.ax);
        break;
      case '-':
        generator.op.neg(generator.r.ax);
        break;
      case '+':
        break;
      case '*':
        generator.op.lea(generator.r.ax, generator.r.ax);
        break;
      case '&':
        break;
      default:
        throw new Error(`operator not implemented: ${statement.operator}`);
    }
  },
};

function visit(generator, statements, tag) {
  statements.forEach((st) => {
    try {
      if (!visitors.hasOwnProperty(st.kind)) {
        throw new Error(`statement ${st.kind} not implemented`);
      }
      visitors[st.kind](generator, st, tag);
    } catch (e) {
      console.log('ERROR: TYPE: ' + e.stack + ' CODE: ' + inspect(st) + 'END ERROR \n');
    }
  });
}

// for a given type, return its size in data section
function typeSize(type) {
  if (type.modifiers[0] != null) {
    if (type.modifiers[0].kind == 'ArrayTypeModifier') {
      return (type.modifiers[0].capacity) * 1;
    }
    return 1; // pointer
  } else return 1; // for int and char
}
