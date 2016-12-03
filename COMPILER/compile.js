let parser;

try {
  parser = require('./parser');
} catch (e) {
  console.log('You must build the parser first. Run `npm run build` from COMPILER directory.');
  process.exit(1);
}

const { op, m, l, L, r, mem, label, data, getAssembly, zeros } = require('./gen');

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

console.dir(program);

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
	label(".while" + statement.id;
	handlers[statement.predicate.kind](statement.predicate);//write to ax
	op.test(r.ax, 0);
	op.jz(".endwhile" + statement.id);
	handlers[statement.statement.kind](statement.statement);
	op.jmp(".while" + statement.id);
	label(".endwhile" + statement.id);
  },
  FunctionCallStatement(func) {
	
  },
}

function visit(statements) {
  statements.forEach(function (st) {
    if (!statementHandlers.hasOwnProperty(st.kind)) {
      throw new Error(`statement ${st.kind} not implemented`);
    }
    statementHandlers[st.kind](st);
  });
}

try { visit(program); }
catch (e) {
  console.log('translation error, but printing what we already have');
  console.log(getAssembly());
}

function randomHash() {
  return '.'.repeat(5).split('').map(x => String.fromCharCode(Math.floor(Math.random() * 25) + 97)).join('');
}