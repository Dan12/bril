#!/usr/bin/env node
import * as brili from './brili_base';
import * as brili_mem from './brili_mem';
import * as brili_rec from './brili_rec';
import * as brili_func from './brili_func';
import * as bril from './bril_base';
import * as bril_mem from './bril_mem';
import * as bril_rec from './bril_rec';
import * as bril_func from './bril_func';
import { Heap } from './heap';
import { readStdin } from './util';
import { Composer } from './composer';

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

  let b = new Composer<brili.Action | brili_func.Actions, ProgramState, FunctionState, Instruction, Function>(
    [brili.evalInstr, brili_mem.evalInstr, brili_rec.evalInstr, brili_func.evalInstr],
    [brili.evalAction, brili_func.evalAction],
    initP,
    initF
  );
  b.evalProg(prog);
}

// Make unhandled promise rejections terminate.
process.on('unhandledRejection', e => { throw e });

main();
