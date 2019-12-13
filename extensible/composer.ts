#!/usr/bin/env node
import * as brili from './brili_base';
import * as brili_mem from './brili_mem';
import * as bril_rec from './brili_rec';
import { unreachable, readStdin } from './util';
import { Heap } from './heap';

let mem_ext_eval = brili_mem.evalInstr(brili.evalInstr);
type ProgramState = {heap: brili_mem.ProgramState};
type FunctionState = {env: brili.Env};

function evalFunc(func: any, programState: ProgramState) {
  let functionState = {env: new Map()};
  for (let i = 0; i < func.instrs.length; ++i) {
    let line = func.instrs[i];
    if ('op' in line) {
      let action = mem_ext_eval(line, env);

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

function evalProg(prog: any) {
  let programState = {heap: new Heap<brili_mem.Value>()};
  for (let func of prog.functions) {
    if (func.name === "main") {
      evalFunc(func, programState);
    }
  }
}

async function main() {
  let prog = JSON.parse(await readStdin());
  evalProg(prog);
}

// Make unhandled promise rejections terminate.
process.on('unhandledRejection', e => { throw e });

main();
