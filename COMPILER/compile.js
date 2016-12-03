let parser;

try {
  parser = require('./parser');
} catch (e) {
  console.log('You must build the parser first. Run `npm run build` from COMPILER directory.');
  process.exit(1);
}

const { op, m, l, L, r, mem, label, data, getAssembly, zeros } = require('./gen');

const util = require('util');
const cli = require('meow')(`
  Usage:
    compile INPUT [-o OUTPUT]
`);

const fs = require('fs');
if (cli.input.length < 1) {
  console.log('at leprogram input file required');
  process.exit(1);
}

let program, input;
try {
  input = fs.readFileSync(cli.input[0], 'utf-8');
} catch (e) {
  console.log(`failed to read input file ${cli.input[0]}`);
  process.exit(1);
}
try {
  program = parser.parse(input);
} catch (e) {
  console.log(`failed to parse input: ${e.message}`);
}

//dump(program);

/* for a given type, return its size in data section */
function typeSize(type) {
  if(type.modifiers.length > 0){
	if(type.modifiers[0].kind == 'ArrayTypeModifier'){
		return (type.modifiers[0].capacity) * 2
	}
  }else return 2;//for int and char//16bites == 1* X000000000
}

const statementHandlers = {
  VariableDeclaration({ type, name, initial }) {
    data(name, typeSize(type), initial !== null ? initial.value : zeros(typeSize(type)));
  },
  ConditionalStatement(statement) {
    statement.id = randomHash();
    handlers[statement.predicate.kind](statement.predicate);//write to ax
    op.test(r.ax, 0);
    op.jz(".elseif" + statement.id);
    handlers[statement.statement.kind](statement.statement);
    op.jmp(".endif" + statement.id);
    label(".elseif" + statement.id);
    handlers[statement.elseStatement.kind](statement.elseStatement);
    label(".endif" + statement.id);
  },
  ConditionalLoopStatement(statement) {
    statement.id = randomHash();
    label(".while" + statement.id);
    handlers[statement.predicate.kind](statement.predicate);//write to ax
    op.test(r.ax, 0);
    op.jz(".endwhile" + statement.id);
    handlers[statement.statement.kind](statement.statement);
    op.jmp(".while" + statement.id);
    label(".endwhile" + statement.id);
  },
  AssignmentStatement(statement) {
    handlers[statement.rightHandSide.kind](statement.rightHandSide);//write to ax
    op.mov(l[statement.leftHandSide], r.ax);
  },
  ReturnStatement(statement, { callingConvention }) {
	if(callingConvention == "fastcall") {
		handlers[statement.kind](statement);//write to ax
		op.pop(r.dx);
		op.jmp(r.dx);
	}else{
		handlers[statement.kind](statement);//write to ax
		op.pop(r.dx);
		op.push(r.ax);
		op.jmp(r.dx);
	}
  },
  FunctionDefinition(statement) {
	label(".func" + statement.name);
	if(statement.convention == "fastcall") {
		if(statement.args.length > 4) { throw new Error("too many args for fastcall");}
		reg = 'AX';
		for(i = 0;i > statement.args.length - 1; i++){
			data(statement.args[i].name, typeSize(statement.args[i].type.name), reg);
			switch(reg){
			case 'AX': reg='BX';break;
			case 'BX': reg='CX';break;
			case 'CX': reg='DX';break;
			}
		}
		if (statement.statement.kind != null) {
			handlers[statement.statement.kind](statement.statement);
		}
	}else{
		for(i = 0;i > statement.args.length - 1; i++){
			op.pop(r.dx);
			data(statement.args[i].name, typeSize(statement.args[i].type.name), r.dx);
		}
		if (statement.statement.kind != null) {
			handlers[statement.statement.kind](statement.statement);
		}
	}
  },
  ExpressionStatement(statement) {
	if(statement.expression.kind == 'FunctionCall') {
		if(statement.expression.name == "print_const") {
			for (i = 0 ; statement.expression.args[0].value.length; i++) {
				dumpBinary(b11000001);
				dumpBinary(statement.expression.args[0].value[i]);
			}
		}
		op.cpc();
		op.push(r.dx);
		if(statement.expression.convention == "fastcall"){
			if(statement.expression.args.length > 4) { throw new Error("too many args for fastcall");}
			reg = 'AX';
			for(i = 0;i > statement.expression.args.length - 1 ; i++){
				op.mov(reg, l[statement.expression.args[i].value]);
				switch(reg){
					case 'AX': reg='BX';break;
					case 'BX': reg='CX';break;
					case 'CX': reg='DX';break;
				}
			}
		}else{
			for(i = statement.expression.args.length - 1;i < 0  ; i--){
				op.mov(r.dx, l[statement.expression.args[i].value]);
				op.push(r.dx);
			}
		}
		op.jmp(".func" + statement.expression.name);
	}
	
  }
}

function visit(statements, tag) {
  statements.forEach(function (st) {
  try{
    if (!statementHandlers.hasOwnProperty(st.kind)) {
      throw new Error(`statement ${st.kind} not implemented`);
    }
    statementHandlers[st.kind](st, tag);
  }catch(e){ console.log("ERROR: TYPE: " + e + " CODE: " + dump(st) + "END ERROR \n");}
  });
}

try {
  visit(program, {});
} catch (e) {
  console.log('translation error, but printing what we already have');
  console.log(getAssembly());
}

function randomHash() {
  return '.'.repeat(5).split('').map(x => String.fromCharCode(Math.floor(Math.random() * 25) + 97)).join('');
}

function dump(value) {
  console.log(util.inspect(value, false, null));
}
