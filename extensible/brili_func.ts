#!/usr/bin/env node
import * as bril_base from './bril_base';
import * as bril from './bril_func';
import * as brili from './brili_base';
import { readStdin, unreachable } from './util';

type ReturnValue = brili.Value | null;

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

type Action =
  {"label": bril_base.Ident} |
  {"next": true} |
  {"end": ReturnValue};

/**
 * Interpet a call instruction.
 */
function evalCall(instr: bril.CallOperation, env: brili.Env, funcs: bril.Function[])
  : Action {
  let func = findFunc(instr.name, funcs);
  if (func === null) {
    throw new BriliError(`undefined function ${instr.name}`);
  }

  let newEnv: Env = new Map();

  // check arity of arguments and definition
  if (func.args.length !== instr.args.length) {
    throw new BriliError(`function expected ${func.args.length} arguments, got ${instr.args.length}`);
  }

  for (let i = 0; i < func.args.length; i++) {
    // Look up the variable in the current (calling) environment
    let value = get(env, instr.args[i]);

    // Check argument types
    if (brilTypeToDynamicType[func.args[i].type] !== typeof value) {
      throw new BriliError(`function argument type mismatch`);
    }

    // Set the value of the arg in the new (function) environemt
    newEnv.set(func.args[i].name, value);
  }

  let valueCall : bril.ValueCallOperation = instr as bril.ValueCallOperation;

  // Dynamically check the function's return value and type
  let retVal = evalFuncInEnv(func, funcs, newEnv);
  if (valueCall.dest === undefined && valueCall.type === undefined) {
     // Expected void function
    if (retVal !== null) {
      throw new BriliError(`unexpected value returned without destination`);
    }
    if (func.type !== undefined) {
      throw new BriliError(`non-void function (type: ${func.type}) doesn't return anything`); 
    }
  } else {
    // Expected non-void function
    if (valueCall.type === undefined) {
      throw new BriliError(`function call must include a type if it has a destination`);  
    }
    if (valueCall.dest === undefined) {
      throw new BriliError(`function call must include a destination if it has a type`);  
    }
    if (retVal === null) {
      throw new BriliError(`non-void function (type: ${func.type}) doesn't return anything`);
    }
    if (brilTypeToDynamicType[valueCall.type] !== typeof retVal) {
      throw new BriliError(`type of value returned by function does not match destination type`);
    }
    if (func.type !== valueCall.type ) {
      throw new BriliError(`type of value returned by function does not match declaration`);
    }
    env.set(valueCall.dest, retVal);
  }
  return brili.NEXT;
}