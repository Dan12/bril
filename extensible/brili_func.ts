import * as bril_base from './bril_base';
import * as brili_base from './brili_base';
import * as bril from './bril_func';
import * as util from './util';

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

type CallAction = { "call": bril_base.Ident, "args": bril_base.Ident[] };
type RetAction = { "end": true };
export type Actions = CallAction | RetAction;

export type FunctionState = { env: brili_base.Env };

export type StackFrame<F extends FunctionState> = [F, brili_base.PC];

export type ProgramState<F extends FunctionState> = { functions: bril.Function[], currentFunctionState: F, callStack: StackFrame<F>[], initF: () => F };

const instrOps = ["call"] as const;
// This implements a type equality check for the above array, providing some static safety
type CheckLE = (typeof instrOps)[number] extends (bril.Instruction["op"]) ? any : never;
type CheckGE = (bril.Instruction["op"]) extends (typeof instrOps)[number] ? any : never;
let _: [CheckLE, CheckGE] = [0, 0];

function isInstruction(instr: { op: string }): instr is bril.Instruction {
  // very loose dynamic type saftey
  return instrOps.some(op => op === instr.op);
}

export function evalInstr<A, P extends ProgramState<F>, F extends FunctionState, I extends util.BaseInstruction>(baseEval: (instr: I, programState: P, functionState: F) => A) {
  return (instr: bril.Instruction | I, programState: P, functionState: F): A | Actions => {
    if (isInstruction(instr)) {
      return { "call": instr.args[0], "args": instr.args.slice(1) };
    } else {
      return baseEval(instr, programState, functionState);
    }
  }
}

function isCall(action: any): action is CallAction {
  return 'call' in action;
}

export function evalAction<A, P extends ProgramState<F>, F extends FunctionState>(baseHandle: (action: A, pc: brili_base.PC, programState: P, functionState: F) => brili_base.PC) {
  return (action: A | Actions, pc: brili_base.PC, programState: P, functionState: F): brili_base.PC => {
    let env = functionState.env;
    if ('call' in action) {
      // push current activation record into stack frame
      programState.callStack.push([programState.currentFunctionState, { function: pc.function, index: pc.index + 1 }]);

      // Search for the label and transfer control.
      pc.function = findFunc(action.call, programState.functions);
      pc.index = 0;

      if (pc.function.args.length === action.args.length) {
        let calleeEnv = new Map();
        for (let i = 0; i < pc.function.args.length; i++) {
          let formal = pc.function.args[i];
          let actual = action.args[i];
          let actualVal = env.get(actual);
          if (actualVal != undefined) {
            // if (isCorrectType(actualVal, formal.type)) {
            calleeEnv.set(formal.name, actualVal);
            // } else {
            //   throw `function ${callee.name} argument ${formal.name} has type ${formal.type}`;
            // }

          } else {
            throw `variable ${actual} does not exist`;
          }
        }
        programState.currentFunctionState = programState.initF();
        programState.currentFunctionState.env = calleeEnv;
      } else {
        throw `function requires ${pc.function.args.length} arguments. Got ${action.args.length}`;
      }

      return pc;
    } else if ('end' in action) {
      let oldFrame = programState.callStack.pop();
      if (oldFrame != undefined) {
        let [retState, retPC] = oldFrame;
        programState.currentFunctionState = retState;
        return retPC;
      } else {
        pc.index = pc.function.instrs.length;
        return pc;
      }
    } else {
      return baseHandle(action, pc, programState, functionState);
    }
  }
}

