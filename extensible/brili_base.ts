import * as bril from './bril_base';
import { unreachable, BaseInstruction, BaseFunction } from './util';

export type Value = boolean | BigInt;
export type Env = Map<bril.Ident, any>;

export function get<T>(env: Map<bril.Ident, T>, ident: bril.Ident): T {
  let val = env.get(ident);
  if (typeof val === 'undefined') {
    throw `undefined variable ${ident}`;
  }
  return val;
}

interface op_and_args {
  args: bril.Ident[];
  op: string;
}

/**
 * Ensures that accessing the argument at [index] is a valid access.
 * Throws an exception instead of returning undefined
 */
function safeArgGet(instr: op_and_args, index: number) {
  if (instr.args.length <= index) {
    throw `${instr.op} only has ${instr.args.length} argument(s); tried to access argument ${index}`;
  }
  return instr.args[index];
}

export function getInt(instr: op_and_args, env: Env, index: number) {
  let val = get(env, safeArgGet(instr, index));
  if (typeof val !== 'bigint') {
    throw `${instr.op} argument ${index} must be a number`;
  }
  return val;
}

export function getBool(instr: op_and_args, env: Env, index: number) {
  let val = get(env, safeArgGet(instr, index));
  if (typeof val !== 'boolean') {
    throw `${instr.op} argument ${index} must be a boolean`;
  }
  return val;
}

/**
 * The thing to do after interpreting an instruction: either transfer
 * control to a label, go to the next instruction, or end thefunction.
 */
type Label = { "label": bril.Ident };
type End = { "end": true };
type Next = { "next": true };
export type Action = Label | Next | End;
export let NEXT: Action = { "next": true };
export let END: Action = { "end": true };

export type ProgramState = {}
export type FunctionState = { env: Env };

const instrOps = ["const", "add", "mul", "sub", "div", "id", "nop", "eq", "lt", "gt", "ge", "le", "not", "and", "or", "br", "jmp", "print", "ret"] as const;
// This implements a type equality check for the above array, providing some static safety
type CheckLE = (typeof instrOps)[number] extends (bril.OpCode) ? any : never;
type CheckGE = (bril.OpCode) extends (typeof instrOps)[number] ? any : never;
let _: [CheckLE, CheckGE] = [0, 0];

function isInstruction(instr: { op: string }): instr is bril.Instruction {
  // very loose dynamic type saftey
  return instrOps.some(op => op === instr.op);
}

/**
 * Interpret an instruction in a given environment, possibly updating the
 * environment. If the instruction branches to a new label, return that label;
 * otherwise, return "next" to indicate that we should proceed to the next
 * instruction or "end" to terminate the function.
 */
export function evalInstr<A, P extends ProgramState, F extends FunctionState, I extends BaseInstruction>(baseEval: (instr: I, programState: P, functionState: F) => A) {
  return (instr: bril.Instruction | I, programState: P, functionState: F): A | Action => {
    let env = functionState.env;
    if (isInstruction(instr)) {
      switch (instr.op) {
        case "const":
          // Ensure that JSON ints get represented appropriately.
          let value: Value;
          if (typeof instr.value === "number") {
            value = BigInt(instr.value);
          } else {
            value = instr.value;
          }

          env.set(instr.dest, value);
          return NEXT;

        case "id": {
          let val = get(env, safeArgGet(instr, 0));
          env.set(instr.dest, val);
          return NEXT;
        }

        case "add": {
          let val = getInt(instr, env, 0) + getInt(instr, env, 1);
          env.set(instr.dest, val);
          return NEXT;
        }

        case "mul": {
          let val = getInt(instr, env, 0) * getInt(instr, env, 1);
          env.set(instr.dest, val);
          return NEXT;
        }

        case "sub": {
          let val = getInt(instr, env, 0) - getInt(instr, env, 1);
          env.set(instr.dest, val);
          return NEXT;
        }

        case "div": {
          let val = getInt(instr, env, 0) / getInt(instr, env, 1);
          env.set(instr.dest, val);
          return NEXT;
        }

        case "le": {
          let val = getInt(instr, env, 0) <= getInt(instr, env, 1);
          env.set(instr.dest, val);
          return NEXT;
        }

        case "lt": {
          let val = getInt(instr, env, 0) < getInt(instr, env, 1);
          env.set(instr.dest, val);
          return NEXT;
        }

        case "gt": {
          let val = getInt(instr, env, 0) > getInt(instr, env, 1);
          env.set(instr.dest, val);
          return NEXT;
        }

        case "ge": {
          let val = getInt(instr, env, 0) >= getInt(instr, env, 1);
          env.set(instr.dest, val);
          return NEXT;
        }

        case "eq": {
          let val = getInt(instr, env, 0) === getInt(instr, env, 1);
          env.set(instr.dest, val);
          return NEXT;
        }

        case "not": {
          let val = !getBool(instr, env, 0);
          env.set(instr.dest, val);
          return NEXT;
        }

        case "and": {
          let val = getBool(instr, env, 0) && getBool(instr, env, 1);
          env.set(instr.dest, val);
          return NEXT;
        }

        case "or": {
          let val = getBool(instr, env, 0) || getBool(instr, env, 1);
          env.set(instr.dest, val);
          return NEXT;
        }

        case "print": {
          let values = instr.args.map(i => get(env, i).toString());
          console.log(...values);
          return NEXT;
        }

        case "jmp": {
          return { "label": safeArgGet(instr, 0) };
        }

        case "br": {
          let cond = getBool(instr, env, 0);
          if (cond) {
            return { "label": safeArgGet(instr, 1) };
          } else {
            return { "label": safeArgGet(instr, 2) };
          }
        }

        case "ret": {
          return END;
        }

        case "nop": {
          return NEXT;
        }
      }
    } else {
      return baseEval(instr, programState, functionState);
    }
    return unreachable(instr);
  }
}

export type PC<I extends BaseInstruction, F extends BaseFunction<I>> = { function: F; index: number };

function isLabel(action: any): action is Label {
  return 'label' in action;
}

function isEnd(action: any): action is End {
  return 'end' in action
}

function isNext(action: any): action is Next {
  return 'next' in action
}

export function evalAction<A, P extends ProgramState, FS extends FunctionState, I extends BaseInstruction, F extends BaseFunction<I>>(baseHandle: (action: A, pc: PC<I,F>, programState: P, functionState: FS) => PC<I,F>) {
  return (action: A | Action, pc: PC<I,F>, programState: P, functionState: FS): PC<I,F> => {
  if (isLabel(action)) {
    // Search for the label and transfer control.
    let i = 0;
    for (; i < pc.function.instrs.length; ++i) {
      let sLine = pc.function.instrs[i];
      if ('label' in sLine && sLine.label === action.label) {
        break;
      }
    }
    if (i === pc.function.instrs.length) {
      throw `label ${action.label} not found`;
    }
    pc.index = i;

    return pc;
  } else if (isEnd(action)) {
    pc.index = pc.function.instrs.length;

    return pc;
  } else if (isNext(action)) {
    pc.index++;

    return pc;
  } else {
    return baseHandle(action, pc, programState, functionState);
  }
}
}