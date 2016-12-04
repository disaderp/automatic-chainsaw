
const out = [];
const dataEntries = [];

const r = {
  ax: { type: 'register', size: 2, toString() { return 'AX'; } },
  bx: { type: 'register', size: 2, toString() { return 'BX'; } },
  cx: { type: 'register', size: 2, toString() { return 'CX'; } },
  dx: { type: 'register', size: 2, toString() { return 'DX'; } },
};

function paramSize(param) {
  if (typeof param === 'number') return immediateSize;
  else return param.size;
}

function paramToString(param) {
  if (typeof param === 'number') return `(${param})`;
  else return String(param);
}

const op = new Proxy({}, {
  get(target, property, receiver) {
    return function (...params) {
      out.push(`${property.toUpperCase()} ${params.map(paramToString).join(',')}`);
    };
  },
});

function data(name, size, bytes) {
  dataEntries.push({ name, size, bytes });
}

function dumpBinary(bytes) {
  if (typeof bytes === 'number') return bytes.toString(2);
  else if (typeof bytes === 'string') return bytes
    .split('')
    .map(b => b.charCodeAt(0))
    .filter(b => b < 0x100)
    .map(b => '0'.repeat(8 - b.toString(2).length) + b.toString(2))
    .join('\nX');
  else console.log("throw new Error(`dumpBinary(): unexpected type ${typeof bytes}`)");
}

function zeros(count) {
  return '\0'.repeat(count);
}

function label(name) {
  out.push(`.${name}`);
}

const l = new Proxy({}, {
  get(target, property) {
    return { type: 'label', size: 2, toString() { return `.${property}`; } };
  },
});

const L = new Proxy({}, {
  get(target, property) {
    return { type: 'label+memory', size: 2, toString() { return `[.${property}]`; } };
  },
});

function m(address) {
  return { type: 'memory', size: 2, toString() { return `[${address.toString(2)}]`; } };
}

function mem(name, address) {
  m[name] = { type: 'memory',  };
}

function getAssembly() {
  return out.join('\n') + '\n' + dataEntries.map(function (datum) {
    return `.${datum.name}\n` +
           `X${dumpBinary(datum.bytes)}`;
  }).join('\n')
}

Object.assign(exports, { op, m, l, L, r, mem, label, data, getAssembly, dumpBinary, zeros });
