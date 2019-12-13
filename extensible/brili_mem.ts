import { Heap, Key } from './heap';
import * as bril from './bril_mem';
import * as brili_base from './brili_base';

type Pointer = {
  loc: Key;
  type: bril.Type;
}

export type Value = boolean | Pointer | BigInt;

export type ProgramState = {heap: Heap<Value>};
export type FunctionState = {env: brili_base.Env};

function alloc(ptrType: bril.PointerType, amt: number, heap: Heap<Value>): Pointer {
  if (typeof ptrType != 'object') {
    throw `unspecified pointer type ${ptrType}`
  } else if (amt <= 0) {
    throw `must allocate a positive amount of memory: ${amt} <= 0`
  } else {
    let loc = heap.alloc(amt)
    let dataType = ptrType.ptr;
    if (dataType !== "int" && dataType !== "bool") {
      dataType = "ptr";
    }
    return {
      loc: loc,
      type: dataType
    }
  }
}

function getPtr(instr: bril.Operation, env: brili_base.Env, index: number): Pointer {
  let val = brili_base.get(env, instr.args[index]);
  if (typeof val !== 'object' || val instanceof BigInt) {
    throw `${instr.op} argument ${index} must be a Pointer`;
  }
  return val;
}

export function evalInstr<A,P extends ProgramState,F extends FunctionState>(ext_eval: (instr: A, programState:P, functionState:F) => brili_base.Action) {
  return (instr: any, programState:P, functionState:F): brili_base.Action => {
    let heap = programState.heap;
    let env = functionState.env;
    switch (instr.op) {
      case "alloc": {
        let amt = brili_base.getInt(instr, env, 0)
        let ptr = alloc(instr.type, Number(amt), heap)
        env.set(instr.dest, ptr);
        return brili_base.NEXT;
      }

      case "free": {
        let val = getPtr(instr, env, 0)
        heap.free(val.loc);
        return brili_base.NEXT;
      }

      case "store": {
        let target = getPtr(instr, env, 0)
        switch (target.type) {
          case "int": {
            heap.write(target.loc, brili_base.getInt(instr, env, 1))
            break;
          }
          case "bool": {
            heap.write(target.loc, brili_base.getBool(instr, env, 1))
            break;
          }
          case "ptr": {
            heap.write(target.loc, getPtr(instr, env, 1))
            break;
          }
        }
        return brili_base.NEXT;
      }

      case "load": {
        let ptr = getPtr(instr, env, 0)
        let val = heap.read(ptr.loc)
        if (val == undefined || val == null) {
          throw `Pointer ${instr.args[0]} points to uninitialized data`;
        } else {
          env.set(instr.dest, val)
        }
        return brili_base.NEXT;
      }

      case "ptradd": {
        let ptr = getPtr(instr, env, 0)
        let val = brili_base.getInt(instr, env, 1)
        env.set(instr.dest, { loc: ptr.loc.add(Number(val)), type: ptr.type })
        return brili_base.NEXT;
      }

      default: {
        return ext_eval(instr, programState, functionState);
      }
    }

  }
}