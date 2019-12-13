#!/usr/bin/env node
import * as brili from './brili_base';
import * as brili_mem from './brili_mem';
import * as bril_rec from './brili_rec';
import { unreachable, readStdin } from './util';
import { Heap } from './heap';

type evalFunc<P,F> = (instr: any, programState:P, functionState:F) => brili.Action;

class Brili<P,F> {
  evalInstr: evalFunc<P,F>;
  initP: () => P;
  initF: () => F;

  constructor(base: evalFunc<P,F>, exts: ((ext_func : evalFunc<P,F>) => evalFunc<P,F>)[], initP: () => P, initF: () => F) {
    this.evalInstr = base;
    for (let ext of exts) {
      this.evalInstr = ext(this.evalInstr);
    }
    this.initP = initP;
    this.initF = initF;
  }

  evalFunc(func: any, programState: P) {
    let functionState = this.initF();
    for (let i = 0; i < func.instrs.length; ++i) {
      let line = func.instrs[i];
      if ('op' in line) {
        let action = this.evalInstr(line, programState, functionState);
  
        if ('label' in action) {
          // Search for the label and transfer control.
          for (i = 0; i < func.instrs.length; ++i) {
            let sLine = func.instrs[i];
            if ('label' in sLine && sLine.label === action.label) {
              break;
            }
          }
          if (i === func.instrs.length) {
            throw `label ${action.label} not found`;
          }
        } else if ('end' in action) {
          return;
        }
      }
    }
  }
  
  evalProg(prog: any) {
    let programState = this.initP();
    for (let func of prog.functions) {
      if (func.name === "main") {
        this.evalFunc(func, programState);
      }
    }
  }
}

async function main() {
  let prog = JSON.parse(await readStdin());

  let initP = () => {
    return {heap: new Heap<brili_mem.Value>()};
  };
  let initF = () => {
    return {env: new Map()};
  };
  
  let b = new Brili<brili_mem.ProgramState, brili_mem.FunctionState>(brili.evalInstr, [brili_mem.evalInstr], initP, initF);
  b.evalProg(prog);
}

// Make unhandled promise rejections terminate.
process.on('unhandledRejection', e => { throw e });

main();
