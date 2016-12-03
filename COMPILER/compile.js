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

dump(program);

/* for a given type, return its size in data section */
function typeSize(type) {
  // FIXME: ignores modifiers (pointer, array)
  switch (type.name) {
    case 'int':
      return 0x2;
    case 'char':
      return 0x1;
    default:
      throw new TypeError(`type ${type.name} not implemented`);
  }
}

const statementHandlers = {
  VariableDeclaration({ type, name, initial }) {
    data(name, typeSize(type), initial.value !== null ? initial.value : zeros(typeSize(type)));
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
    if(statement.leftHandSide.type == "int" || statement.leftHandSide.type == "char"){
      handlers[statement.rightHandSide.kind](statement.rightHandSide);//write to ax
      op.mov(l[statement.leftHandSide.name], r.ax);
    }else{
      throw new Error("not implemented");
    }
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
		//todo: for all arguments(max 4
		data(name, typeSize(type), r.ax);//then bx, cx,dx
		//eval instrtuctions
	}else{
		throw new Error("todo");
	}
  },
  ExpressionStatement(statement) {
	if(statement.type == FunctionCall) {
		op.cpc();
		op.push(r.dx);
		if(statement.FunctionCall.convention == "fastcall"){
			//for all args //max 4
			op.mov(r.ax, l[args[i]]);//then bx,cx,dx
		}else{
			//for all args REV ORDER!!
			op.mov(r.dx, l[args[i]]);
			op.push(r.dx);
		}
		op.jmp(".func" + statement.FunctionCall.name);
	}
	
  }
}

function visit(statements, tag) {
  statements.forEach(function (st) {
    if (!statementHandlers.hasOwnProperty(st.kind)) {
      throw new Error(`statement ${st.kind} not implemented`);
    }
    statementHandlers[st.kind](st, tag);
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
