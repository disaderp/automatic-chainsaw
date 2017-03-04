const util = require('util');
let parser = require('./parser');

const fs = require('fs');

function preprocessFile(fileName) {
  return preprocess(fs.readFileSync(fileName, 'utf-8').split(/\r?\n/));
};

function preprocess(lines) {
  const macros = {};

  function Macro() {
  }

  return {
    macros,
    code: lines
      .map(function processLine(line) {
        if (!line.startsWith('#')) {
          return line;
        }
        const tokens = line.substr(1).split(/\s+/g);

        if (!tokens[0])
          return '';

        switch (tokens[0]) {
          case 'include': {
            const _ = preprocessFile(tokens[1]);
            Object.assign(macros, _.macros);
            return _.code;
          }
          case 'define':
            macros[tokens[1]] = parser.parse(tokens.slice(2).join(' '), {
              startRule: 'Expression',
            });
            break;
          default:
            throw new Error(`unknown preprocessor directive: ${tokens[0]}`);
        }
      })
      .join('\n')
  };
}

module.exports = { preprocess, preprocessFile };

