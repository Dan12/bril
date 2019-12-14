import * as bril from './bril_rec';
import * as brili_base from './brili_base';
import * as util from './util';

type Value = brili_base.Value | Record;
type RecordBindings = { [index: string]: Value };
export type TypeEnv = Map<bril.Ident, bril.RecordType>;

interface Record {
  name: string;
  bindings: RecordBindings;
}

/**
 * Creates a new record given record bindings and a name;
 * @param o RecordBindings to copy
 * @param name Name of new record
 */
function copy(o: RecordBindings, name: string) {
  var output : Record, v, key;
  output = {name: name, bindings: {}};
  for (key in o) {
      v = o[key];
      if (typeof v === "boolean" || typeof v === 'bigint') {
        output.bindings[key] = v;
      } else {
        output.bindings[key] = copy((v as Record).bindings, (v as Record).name)
      }
  }
  return output;
}

function checkIntVal(val: any, index: number | string, op: string) {
  if (typeof val !== 'bigint') {
    throw `${op} argument ${index} must be a number`;
  }
  return val;
}

function checkBoolVal(val: any, index: number | string, op: string) : boolean {
  if (typeof val !== 'boolean') {
    throw `${op} argument ${index} must be a number`;
  }
  return val;
}


/**
 * Creates a record given. Used for opcodes 'recordinst' and 'with'
 * @param init Optional field initialization for new record.
 *             Used for 'with' syntax.
 */
function createRecord(instr: bril.RecordOperation, env: brili_base.Env, typeEnv: TypeEnv, init?: Record) : Record {
  let record = brili_base.get(typeEnv, instr.type);
  let fieldList = instr.fields;
  let rec : Record = {name: instr.type, bindings: {}};
  if (!init) { 
    fieldList = record;
  } else {
    rec = copy(init.bindings, instr.type);
  }
  for (let field in fieldList) {
    let declared_type : bril.Type | bril.Ident = record[field];
    var val : Value = brili_base.get(env, instr.fields[field]);
    if (declared_type === "boolean") {
      val = checkBoolVal(val, field, instr.op);
    } else if (declared_type === "int") {
      val = checkIntVal(val, field, instr.op);
    } else {
      if ((val as Record).name != declared_type) {
        throw `${instr.op} argument ${field} must be a ${declared_type}`;
      } 
    }
    rec.bindings[field] = val;
  }
  return rec;
}

const instrOps = ["recorddef", "recordinst", "recordwith", "access"] as const;
// This implements a type equality check for the above array, providing some static safety
type CheckLE = (typeof instrOps)[number] extends (bril.Instruction["op"]) ? any : never;
type CheckGE = (bril.Instruction["op"]) extends (typeof instrOps)[number] ? any : never;
let _:[CheckLE, CheckGE] = [0,0];

export type ProgramState = {};
export type FunctionState = {env: brili_base.Env, typeEnv: TypeEnv};

function isInstruction(instr: {op:string}): instr is bril.Instruction {
  // very loose dynamic type saftey
  return instrOps.some(op => op === instr.op);
}

export function evalInstr<A,P extends ProgramState,F extends FunctionState,I extends util.BaseInstruction>(baseEval: (instr: I, programState:P, functionState:F) => A) {
  return (instr: bril.Instruction | I, programState:P, functionState:F): A | brili_base.Action => {
    let typeEnv = functionState.typeEnv;
    let env = functionState.env;
    if (isInstruction(instr)) {
      switch (instr.op) {
        case "recorddef": {
          typeEnv.set(instr.recordname, instr.fields);
          return brili_base.NEXT;
        }
      
        case "recordinst": {
          let val = createRecord(instr, env, typeEnv);
          env.set(instr.dest, val);
          return brili_base.NEXT;
        }
      
        case "recordwith": {
          let src_record = brili_base.get(env, instr.src) as Record; 
          let val = createRecord(instr, env, typeEnv, src_record);
          env.set(instr.dest, val);
          return brili_base.NEXT;
        }
  
        case "access": {
          let record = brili_base.get(env, instr.args[0]);
          let val = (record as Record).bindings[instr.args[1]];
          env.set(instr.dest, val);
          return brili_base.NEXT;
        }
      }
    } else {
      return baseEval(instr, programState, functionState);
    }
    
    return util.unreachable(instr);
  }
}