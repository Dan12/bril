#!/usr/bin/env node
import * as brili from './brili_base';
import * as brili_mem from './brili_mem';
import * as brili_rec from './brili_rec';
import { readStdin } from './util';
import { Heap } from './heap';

type evalFunc<A, P, F> = (instr: any, programState: P, functionState: F) => A;

type PC = brili.PC;

type actionHandler<A, P, F> = (action: A, pc: PC, programState: P, functionState: F) => PC;

interface MinProgramState<F> {
  currentFunctionState : F
}

class Brili<A, P extends MinProgramState<F>, F> {
  evalInstr: evalFunc<A, P, F>;
  handleAction: actionHandler<A, P, F>;
  initP: () => P;
  initF: () => F;

  constructor(base: evalFunc<A, P, F>, exts: ((extFunc: evalFunc<A, P, F>) => evalFunc<A, P, F>)[], initP: () => P, initF: () => F, handleAction: actionHandler<A, P, F>) {
    this.evalInstr = base;
    for (let ext of exts) {
      this.evalInstr = ext(this.evalInstr);
    }
    this.initP = initP;
    this.initF = initF;
    this.handleAction = handleAction;
  }

  eval(pc: PC, programState: P) {
    while (pc.index < pc.function.instrs.length) {
      let line = pc.function.instrs[pc.index];
      if ('op' in line) {
        let action = this.evalInstr(line, programState, programState.currentFunctionState);
        pc = this.handleAction(action, pc, programState, programState.currentFunctionState);
      } else {
        pc.index++;
      }
    }
  }

  evalProg(prog: any) {
    let programState = this.initP();
    for (let func of prog.functions) {
      if (func.name === "main") {
        let pc = { function: func, index: 0 };
        this.eval(pc, programState);
        break;
      }
    }
  }
}

type FunctionState = { env: brili.Env, typeEnv: brili_rec.TypeEnv };
type ProgramState = { heap: Heap<brili_mem.Value>, currentFunctionState:FunctionState };

async function main() {
  let prog = JSON.parse(await readStdin());

  let initF = () => {
    return { env: new Map(), typeEnv: new Map() };
  };
  let initP = () => {
    return { heap: new Heap<brili_mem.Value>(), currentFunctionState: initF() };
  };

  let b = new Brili<brili.Action, ProgramState, FunctionState>(brili.evalInstr, [brili_mem.evalInstr, brili_rec.evalInstr], initP, initF, brili.evalAction);
  b.evalProg(prog);
}

// Make unhandled promise rejections terminate.
process.on('unhandledRejection', e => { throw e });

main();
