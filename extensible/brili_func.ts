import * as bril_base from './bril_base';
import * as brili_base from './brili_base';
import * as bril from './bril_func';
import * as brili from './brili_base';

class BriliError extends Error {
  constructor(message?: string) {
    super(message);
    Object.setPrototypeOf(this, new.target.prototype);
    this.name = BriliError.name;
  }
}

function findFunc(func: bril_base.Ident, funcs: bril.Function[]) {
  let matches = funcs.filter(function (f: bril.Function) {
    return f.name === func;
  });

  if (matches.length == 0) {
    throw new BriliError(`no function of name ${func} found`);
  } else if (matches.length > 1) {
    throw new BriliError(`multiple functions of name ${func} found`);
  }

  return matches[0];
}

type CallAction =
  { "call": bril_base.Ident, "args": bril_base.Ident[] };

export type FunctionState = {};

type StackFrame<F extends FunctionState> = [bril.Function, F, brili_base.PC];

export type ProgramState<F extends FunctionState> = { functions: bril.Function[], currentFunctionState: F, callStack: StackFrame<F>[] };

export function evalInstr<A, P extends ProgramState<F>, F extends FunctionState>(baseEval: (instr: any, programState: P, functionState: F) => A) {
  return (instr: any, programState: P, functionState: F): A | CallAction => {
    switch (instr.op) {
      case "call": {
        return { "call": instr.args[0], "args": instr.args.slice(1) };
      }

      default: {
        return baseEval(instr, programState, functionState);
      }

    }
  }
}

export function evalAction<A extends CallAction, P extends ProgramState<F>,F extends FunctionState>(baseHandle: (action: A, pc: brili_base.PC, programState: P, functionState: F) => brili_base.PC) {
  return (action: A, pc: brili_base.PC, programState: P, functionState: F): brili_base.PC => {
    if ('call' in action) {
      // Search for the label and transfer control.
      
      return pc;
    } else {
      return baseHandle(action, pc, programState, functionState);
    }
  }
}
  
  