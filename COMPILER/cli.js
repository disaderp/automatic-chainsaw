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

try {
  parser = require('./parser');
} catch (e) {
  console.log('You must build the parser first. Run `npm run build` from COMPILER directory.');
  process.exit(1);
}

const { preprocessFile } = require('./preprocess');
const { compile } = require('./compile');

let assembler, program, code, macros;
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
  console.log(`failed to parse input: ${e.stack}`);
  process.exit(1);
}

function expandMacros(program) {
  function traverseAST(visitor, tree = null) {
    if (tree === null) {
      return (tree) => {
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

if (cli.flags.tree) {
  inspect(program);
}

assembler = compile(program);

if (cli.flags.o != null) {
  try {
    input = fs.writeFileSync(cli.flags.o, assembler);
  } catch (e) {
    console.log(`failed to write output file ${cli.flags.o}`);
    process.exit(1);
  }
} else {
  console.log(assembler);
}

