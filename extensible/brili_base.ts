import * as bril from './bril_base';
import {unreachable} from './util';

export type Value = boolean | BigInt;
export type Env = Map<bril.Ident, any>;

export function get<T>(env: Map<bril.Ident, T>, ident: bril.Ident):T {
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
export type Action =
  {"label": bril.Ident} |
  {"next": true} |
  {"end": true};
export let NEXT: Action = {"next": true};
export let END: Action = {"end": true};

/**
 * Interpret an instruction in a given environment, possibly updating the
 * environment. If the instruction branches to a new label, return that label;
 * otherwise, return "next" to indicate that we should proceed to the next
 * instruction or "end" to terminate the function.
 */
export function evalInstr(instr: bril.Instruction, env: Env): Action {
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
    return {"label": safeArgGet(instr, 0)};
  }

  case "br": {
    let cond = getBool(instr, env, 0);
    if (cond) {
      return {"label": safeArgGet(instr, 1)};
    } else {
      return {"label": safeArgGet(instr, 2)};
    }
  }
  
  case "ret": {
    return END;
  }

  case "nop": {
    return NEXT;
  }
  }
  unreachable(instr);
  throw `unhandled opcode ${(instr as any).op}`;
}
