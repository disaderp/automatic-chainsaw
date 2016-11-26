let parser;

try {
  parser = require('./parser');
} catch (e) {
  console.log('ERROR: You must build the parser first. Run `npm run build` from COMPILER directory.');
  process.exit(1);
}

const cli = require('meow')(`
  Usage:
    compile INPUT [-o OUTPUT]
`);

const fs = require('fs');
if (cli.input.length < 1) {
  console.log('ERROR: at letree input file required');
  process.exit(1);
}

let tree, input;
try {
  input = fs.readFileSync(cli.input[0], 'utf-8');
} catch (e) {
  console.log(`ERROR: failed to read input file ${cli.input[0]}`);
  process.exit(1);
}
try {
  tree = parser.parse(input);
} catch (e) {
  console.log(`ERROR: failed to parse input: ${e.message}`);
}

console.dir(tree);
// work your magic
