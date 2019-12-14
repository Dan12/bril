#!/usr/bin/env node
import * as brili from './brili_base';
import * as brili_mem from './brili_mem';
import * as brili_rec from './brili_rec';
import * as brili_func from './brili_func';
import * as bril from './bril_base';
import * as bril_mem from './bril_mem';
import * as bril_rec from './bril_rec';
import * as bril_func from './bril_func';
import { readStdin, BaseInstruction, BaseFunction } from './util';
import { Heap } from './heap';

type evalFunc<A, P, F, I> = (instr: I, programState: P, functionState: F) => A;

type actionHandler<A, P, FS, I extends BaseInstruction, F extends BaseFunction<I>> = (action: A, pc: brili.PC<I, F>, programState: P, functionState: FS) => brili.PC<I, F>;

interface MinProgramState<F> {
  currentFunctionState: F
}

class Brili<A, P extends MinProgramState<FS>, FS, I extends BaseInstruction, F extends BaseFunction<I>> {
  evalInstr: evalFunc<A, P, FS, I>;
  handleAction: actionHandler<A, P, FS, I, F>;
  initP: () => P;
  initF: () => FS;

  constructor(evalExts: ((extFunc: evalFunc<A, P, FS, I>) => evalFunc<A, P, FS, I>)[], actionHandleExts: ((extFunc: actionHandler<A, P, FS, I, F>) => actionHandler<A, P, FS, I, F>)[], initP: () => P, initF: () => FS) {
    this.evalInstr = (instr,_programState,_functionState) => {
      throw `unhandled instruction: ${instr.op}`;
    }
    for (let ext of evalExts) {
      this.evalInstr = ext(this.evalInstr);
    }

    this.handleAction = (_action,_pc,_programState,_functionState) => {
      throw `unhandled action`;
    };
    for (let ext of actionHandleExts) {
      this.handleAction = ext(this.handleAction);
    }

    this.initP = initP;
    this.initF = initF;
  }

  eval(pc: brili.PC<I, F>, programState: P) {
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

type Instruction = bril.Instruction | bril_mem.Instruction | bril_rec.Instruction | bril_func.Instruction;
type Function = bril_func.Function<Instruction>;

type FunctionState = { env: brili.Env, typeEnv: brili_rec.TypeEnv };
let initF = () => {
  return { env: new Map(), typeEnv: new Map() };
};

type ProgramState = { heap: Heap<brili_mem.Value>, currentFunctionState: FunctionState, functions: any, callStack: brili_func.StackFrame<FunctionState, Instruction, Function>[], initF: () => FunctionState };
let initPFunc = (functions: any) => {
  return () => {
    return { heap: new Heap<brili_mem.Value>(), currentFunctionState: initF(), functions: functions, callStack: [], initF: initF };
  };
}

async function main() {
  let prog = JSON.parse(await readStdin());
  let initP = initPFunc(prog.functions);

  let b = new Brili<brili.Action | brili_func.Actions, ProgramState, FunctionState, Instruction, Function>([brili.evalInstr, brili_mem.evalInstr, brili_rec.evalInstr, brili_func.evalInstr], [brili.evalAction, brili_func.evalAction], initP, initF);
  b.evalProg(prog);
}

// Make unhandled promise rejections terminate.
process.on('unhandledRejection', e => { throw e });

main();
