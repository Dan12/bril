#!/usr/bin/env node
import * as brili from './brili_base';
import * as brili_mem from './brili_mem';
import * as brili_rec from './brili_rec';
import * as brili_func from './brili_func';
import * as bril from './bril_base';
import * as bril_mem from './bril_mem';
import * as bril_rec from './bril_rec';
import * as bril_func from './bril_func';
import { readStdin, BaseInstruction } from './util';
import { Heap } from './heap';

type evalFunc<A, P, F, I> = (instr: I, programState: P, functionState: F) => A;

type PC = brili.PC;

type actionHandler<A, P, F> = (action: A, pc: PC, programState: P, functionState: F) => PC;

interface MinProgramState<F> {
  currentFunctionState: F
}

class Brili<A, P extends MinProgramState<F>, F, I extends BaseInstruction> {
  evalInstr: evalFunc<A, P, F, I>;
  handleAction: actionHandler<A, P, F>;
  initP: () => P;
  initF: () => F;

  constructor(evalExts: ((extFunc: evalFunc<A, P, F, I>) => evalFunc<A, P, F, I>)[], initP: () => P, initF: () => F, baseActionHandle: actionHandler<A, P, F>, actionHandleExts: ((extFunc: actionHandler<A, P, F>) => actionHandler<A, P, F>)[]) {
    this.evalInstr = (instr,_programState,_functionState) => {
      throw `unhandled instruction: ${instr.op}`;
    }
    for (let ext of evalExts) {
      this.evalInstr = ext(this.evalInstr);
    }

    this.initP = initP;
    this.initF = initF;
    this.handleAction = baseActionHandle;
    for (let ext of actionHandleExts) {
      this.handleAction = ext(this.handleAction);
    }
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
let initF = () => {
  return { env: new Map(), typeEnv: new Map() };
};

type ProgramState = { heap: Heap<brili_mem.Value>, currentFunctionState: FunctionState, functions: any, callStack: brili_func.StackFrame<FunctionState>[], initF: () => FunctionState };
let initPFunc = (functions: any) => {
  return () => {
    return { heap: new Heap<brili_mem.Value>(), currentFunctionState: initF(), functions: functions, callStack: [], initF: initF };
  };
}

async function main() {
  let prog = JSON.parse(await readStdin());
  let initP = initPFunc(prog.functions);

  let b = new Brili<brili.Action | brili_func.Actions, ProgramState, FunctionState, bril.Instruction | bril_mem.Instruction | bril_rec.Instruction>([brili.evalInstr, brili_mem.evalInstr, brili_rec.evalInstr], initP, initF, brili.evalAction, []);
  b.evalProg(prog);
}

// Make unhandled promise rejections terminate.
process.on('unhandledRejection', e => { throw e });

main();
