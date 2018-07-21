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
    if (fs.statSync(`${__dirname}/grammar.pegjs`).mtime > fs.statSync(`${__dirname}/parser.js`).mtime) {
        throw 42;
    }

    parser = require('./parser');
} catch (e) {
    console.log('You must (re)build the parser first. Run `npm run build` from COMPILER directory.');
    process.exit(1);
}

const { preprocessFile } = require('./preprocess');
const { compile } = require('./compile');

let program, code, macros;
try {
    const _ = preprocessFile(cli.input[0]);
    code = _.code;
    macros = _.macros;
} catch (e) {
    console.log(`failed to preprocess input file ${cli.input[0]}: ${e.stack}`);
    process.exit(1);
}

function showLocation(location) {
    return `${location.start.line},${location.start.column}-${location.end.line},${location.end.column}`;
}

try {
    program = parser.parse(code, {
        startRule: 'Program',
    });
} catch (e) {
    console.log(`syntax error at (input):${showLocation(e.location)}: ${String(e).replace('SyntaxError: ', '')}`);
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

const { failed, assembly } = compile(program);

if (failed) {
    console.error('compilation failed');
    process.exit(1);
}

if (cli.flags.o != null) {
    try {
        input = fs.writeFileSync(cli.flags.o, assembly);
    } catch (e) {
        console.log(`failed to write output file ${cli.flags.o}`);
        process.exit(1);
    }
} else {
    console.log(assembly);
}

