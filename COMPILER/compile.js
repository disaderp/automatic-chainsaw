let parser;

try {
  parser = require('./parser');
} catch (e) {
  console.log('You must build the parser first. Run `npm run build` from COMPILER directory.');
  process.exit(1);
}

const { db, op, m, l, L, r, mem, label, data, getAssembly, zeros, dumpBinary } = require('./gen');

const util = require('util');
const cli = require('meow')(`
  Usage:
    compile INPUT [FLAGS...] [-o OUTPUT]

  Flags:
    --tree - displays code tree after parsing
`);

const fs = require('fs');
if (cli.input.length < 1) {
  console.log(cli.help);
  process.exit(1);
}

const { preprocessFile } = require('./preproc');

let program, code, macros;
try {
  const _ = preprocessFile(cli.input[0]);
  code = _.code;
  macros = _.macros;
} catch (e) {
  console.log(`failed to preprocess input file ${cli.input[0]}: ${e.stack}`);
  process.exit(1);
}

try {
  program = parser.parse(code, {
    startRule: 'Program',
  });
} catch (e) {
  console.log(`failed to parse input: ${e.message}`);
  process.exit(1);
}

function expandMacros(program) {
  function traverseAST(visitor, tree = null) {
    if (tree === null) {
      return function (tree) {
        return traverseAST(visitor, tree);
      };
    }

    if (typeof tree === 'object') {
      visitor(tree);
      Object.keys(tree).map(k => tree[k]).forEach(traverseAST(visitor));
    }
  }

  traverseAST(function visitor(node) {
    if (node && node.kind === 'Identifier') {
      if (macros.hasOwnProperty(node.toString())) {
        const def = macros[node.toString()];
        for (let prop in def) {
          node[prop] = def[prop];
        }
      }
    }
  }, program);
}

expandMacros(program);

// expandMacros(program);
if (cli.flags.tree) {
  dump(program);
};

/* for a given type, return its size in data section */
function typeSize(type) {
  if(type.modifiers[0] != null){
    if(type.modifiers[0].kind == 'ArrayTypeModifier'){
      return (type.modifiers[0].capacity) * 1
    }
    return 1;//POINTERTYPE
  }else return 1;//for int and char//16bites == 1* X000000000
}

let callingConventions = {};
const statementHandlers = {
  VariableDeclaration({ type, name, initial }) {
    data(name, typeSize(type), initial !== null ? initial.value : zeros(typeSize(type)));
  },
  ConditionalStatement(statement) {
    statement.id = randomHash();

    if(statement.predicate.kind == 'Identifier') {
      op.lea(r.ax, l[statement.predicate]);
    }else if(statement.predicate.kind == 'Integer' || statement.predicate.kind == 'Char'){
      op.mov(r.ax, statement.predicate.value);
    } else {
      statementHandlers[statement.predicate.kind](statement.predicate);
    }

    op.mov(r.cx, 0);
    op.test(r.ax, r.cx);
    op.jz(".elseif" + statement.id);
    for(let i = 0; i< statement.statement.length;i++){
      if (statement.statement[i].kind != null) {
        statementHandlers[statement.statement[i].kind](statement.statement[i]);
      }
    }
    op.jmp(".endif" + statement.id);
    label("elseif" + statement.id);
    for(let i = 0; i< statement.elseStatement.length;i++){
      if (statement.elseStatement[i].kind != null) {
        statementHandlers[statement.elseStatement[i].kind](statement.elseStatement[i]);
      }
    }
    label("endif" + statement.id);
  },
  ConditionalLoopStatement(statement) {
    statement.id = randomHash();
    label("while" + statement.id);

    if(statement.predicate.kind == 'Identifier') {
      op.lea(r.ax, l[statement.predicate]);
    }else if(statement.predicate.kind == 'Integer' || statement.predicate.kind == 'Char'){
      op.mov(r.ax, statement.predicate.value);
    } else {
      statementHandlers[statement.predicate.kind](statement.predicate);
    }

    op.mov(r.cx, 0);
    op.test(r.ax, r.cx);
    op.jz(".endwhile" + statement.id);
    for(let i = 0;i < statement.statement.length;i++){
      if (statement.statement[i].kind != 'Identifier') {
        statementHandlers[statement.statement[i].kind](statement.statement[i]);
      }
    }
    op.jmp(".while" + statement.id);
    label("endwhile" + statement.id);
  },
  AssignmentStatement(statement) {
    if(statement.rightHandSide.kind == 'Identifier') {
      op.lea(r.ax, l[statement.rightHandSide]);
      op.mov(l[statement.leftHandSide], r.ax);
    }else if(statement.rightHandSide.kind == 'Integer' || statement.rightHandSide.kind == 'Char'){
      op.mov(l[statement.leftHandSide], statement.rightHandSide.value);
    } else {
      statementHandlers[statement.rightHandSide.kind](statement.rightHandSide);
      op.mov(l[statement.leftHandSide], r.ax);
    }
  },
  ReturnStatement(statement, { callingConvention }) {
    if(statement.expression.kind == 'Identifier') {
      op.lea(r.ax, l[statement.expression]);
    }else if(statement.expression.kind == 'Integer' || statement.expression.kind == 'Char'){
      op.mov(r.ax, statement.expression.value);
    } else {
      statementHandlers[statement.expression.kind](statement.expression);
    }
    op.pop(r.dx);
    //TODO
    //if(callingConvention != "fastcall") {
    //	op.push(r.ax);
    //}
    op.jmp(r.dx);
  },
  FunctionDefinition(statement) {
    label("func" + statement.name);
    let extra = { callingConvention: statement.convention };
    callingConventions[statement.name] = statement.convention;
    if(statement.convention == "fastcall") {
      if(statement.args.length > 4) { throw new Error("too many args for fastcall");}
      reg = 'AX';
      for(let i = 0;i < statement.args.length; i++){
        data(statement.args[i].name, typeSize(statement.args[i].type), zeros(typeSize(statement.args[i].type)));
        op.mov(l[statement.args[i].name], reg);
        switch(reg){
        case 'AX': reg='BX';break;
        case 'BX': reg='CX';break;
        case 'CX': reg='DX';break;
        }
      }
      for(let i = 0;i < statement.statement.length; i++){
        if (statement.statement[i].kind != null) {
          statementHandlers[statement.statement[i].kind](statement.statement[i], extra);
        }
      }
    }else{
      for(let i = 0;i < statement.args.length; i++){
        op.pop(r.dx);
        data(statement.args[i].name, typeSize(statement.args[i].type), zeros(typeSize(statement.args[i].type)));
        op.mov(l[statement.args[i].name], r.dx);
      }
      for(let i = 0;i < statement.statement.length; i++){
        if (statement.statement[i].kind != null) {
          statementHandlers[statement.statement[i].kind](statement.statement[i], extra);
        }
      }
    }
  },
  ExpressionStatement(statement) {
    if(statement.expression.kind == 'FunctionCall') {
      if(statement.expression.name == "print_const") {
        for (let i = 0 ;i < statement.expression.args[0].value.length; i++) {
          db(0b11000001);
          db(statement.expression.args[0].value[i]);
        }
        return;
      }
      op.cpc();
      op.push(r.dx);
      statement.expression.convention = callingConventions[statement.expression.name];
      if(statement.expression.convention == "fastcall"){
        if(statement.expression.args.length > 4) { throw new Error("too many args for fastcall");}
        reg = 'AX';
        for(let i = 0;i < statement.expression.args.length - 1 ; i++){
          if(statement.expression.args[i].kind == 'Identifier') {
            op.lea(reg, l[statement.expression.args[i]]);
          }else if(statement.expression.kind == 'Integer' || statement.expression.kind == 'Char'){
            op.mov(reg, statement.expression.args[i].value);
          } else {
            throw new Error("do not use expression in fastcall function call");
          }
          switch(reg){
          case 'AX': reg='BX';break;
          case 'BX': reg='CX';break;
          case 'CX': reg='DX';break;
          }
        }
      }else{
        for(let i = statement.expression.args.length - 1;i >= 0; i--){
          if(statement.expression.args[i].kind == 'Identifier') {
            op.lea(r.dx, l[statement.expression.args[i]]);
          }else if(statement.expression.args[i].kind == 'Integer' || statement.expression.args[i].kind == 'Char'){
            op.mov(r.dx, statement.expression.args[i].value);
          } else {
            statementHandlers[statement.expression.args[i].kind](statement.expression.args[i]);//write to ax
            op.mov(r.dx, r.ax);
          }
          op.push(r.dx);
        }
      }
      op.jmp(".func" + statement.expression.name);
    }
  },
  BinaryOperator(statement){
    if(statement.leftOperand.kind == 'Identifier'){
      op.lea(r.dx, l[statement.leftOperand]);
      op.push(r.dx);
    }else if(statement.leftOperand.kind == 'Integer' || statement.leftOperand.kind == 'Char'){
      op.mov(r.dx, statement.leftOperand.value);
      op.push(r.dx);
    } else {
      statementHandlers[statement.leftOperand.kind](statement.leftOperand);//write to ax
      op.push(r.ax);
    }

    if(statement.rightOperand.kind == 'Identifier'){
      op.lea(r.dx, l[statement.rightOperand]);
    }else if(statement.rightOperand.kind == 'Integer' || statement.rightOperand.kind == 'Char'){
      op.mov(r.dx, statement.rightOperand.value);
    } else {
      statementHandlers[statement.rightOperand.kind](statement.rightOperand);//write to ax
      op.mov(r.dx, r.ax);
    }

    op.pop(r.ax);
    switch(statement.operator){
    case '+': op.add(r.ax, r.dx); break;
    case '-': op.sub(r.ax, r.dx); break;
    case '*': op.mul8(r.ax, r.dx); break;
    case '/': op.div8(r.ax, r.dx); break;
    case '&': op.and(r.ax, r.dx); break;
    case '|': op.or(r.ax, r.dx); break;
    case '<<': op.shl(r.ax, r.dx); break;
    case '==': op.test(r.ax, r.dx); statement.id = randomHash(); op.mov(r.ax, 0); op.jnz(l[".testexit" + statement.id]); op.mov(r.ax, 1); label("testexit" + statement.id); break;
    case '<': op.cmp(r.ax, r.dx); statement.id = randomHash(); op.mov(r.ax, 0); op.jnc(l[".testexit" + statement.id]); op.mov(r.ax, 1); label("testexit" + statement.id); break;
    case '>': op.cmp(r.ax, r.dx); statement.id = randomHash(); op.mov(r.ax, 0); op.jno(l[".testexit" + statement.id]); op.mov(r.ax, 1); label("testexit" + statement.id); break;
    case '>=': op.cmp(r.ax, r.dx); statement.id = randomHash(); op.mov(r.ax, 0); op.jc(l[".testexit" + statement.id]); op.mov(r.ax, 1); label("testexit" + statement.id); break;
    case '<=': op.cmp(r.ax, r.dx); statement.id = randomHash(); op.mov(r.ax, 0); op.jo(l[".testexit" + statement.id]); op.mov(r.ax, 1); label("testexit" + statement.id); break;
    default: throw new Error('not implemented operator');
    }
  },

  UnaryOperator (statement){
    if(statement.operand.kind == 'Identifier'){
      op.lea(r.ax, l[statement.operand]);
    }else if(statement.operand.kind == 'Integer' || statement.operand.kind == 'Char'){
      op.mov(r.ax, statement.operand.value);
    } else {
      statementHandlers[statement.operand.kind](statement.operand);//write to ax
      op.push(r.ax);
    }

    switch(statement.operator){
    case '!': op.not(r.ax); break;
    case '~': op.neg(r.ax); break;
    case '-': op.neg(r.ax); break;
    case '+': break;
    case '*': op.lea(r.ax, r.ax); break;
    case '&': break;
    default: throw new Error('not implemented operator');
    }
  },
}

function visit(statements, tag) {
  statements.forEach(function (st) {
    try{
      if (!statementHandlers.hasOwnProperty(st.kind)) {
        throw new Error(`statement ${st.kind} not implemented`);
      }
      statementHandlers[st.kind](st, tag);
    }catch(e){ console.log("ERROR: TYPE: " + e.stack + " CODE: " + dump(st) + "END ERROR \n");}
  });
}

visit(program, {});

if(cli.flags.o != null){
  try {
    input = fs.writeFileSync(cli.flags.o, getAssembly());
  } catch (e) {
    console.log(`failed to read input file ${cli.input[0]}`);
    process.exit(1);
  }
}else{
  console.log(getAssembly());
}

function randomHash() {
  return '.'.repeat(5).split('').map(x => String.fromCharCode(Math.floor(Math.random() * 25) + 97)).join('');
}

function dump(value) {
  console.log(util.inspect(value, false, null));
}
