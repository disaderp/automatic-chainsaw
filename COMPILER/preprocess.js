let parser = require('./parser');
const util = require('util');
const path = require('path');
const fs = require('fs');

function preprocessFile(fileName) {
    return preprocess(fs.readFileSync(fileName, 'utf-8').split(/\r?\n/), fileName);
}

let callingConventions = {};

function preprocess(lines, fileName) {
    const macros = {};

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
                    let includedFilename = tokens[1];
                    if (includedFilename[0] === '"') includedFilename = includedFilename.substr(1, includedFilename.length - 2);
                    const _ = preprocessFile(path.resolve(path.dirname(fileName), includedFilename));
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
            .join('\n'),
    };
}

module.exports = { preprocess, preprocessFile };
