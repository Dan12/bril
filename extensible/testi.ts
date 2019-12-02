#!/usr/bin/env node
import {readStdin, unreachable} from '../bril-ts/util';

export type Ident = string;

export type Value = boolean | bigint;

export type Env = Map<Ident, Value>;

export interface Instruction {
    op: string;
    args: Ident[];
    [x: string]: any;
}

/**
 * Jump labels just mark a position with a name.
 */
export interface Label {
    label: Ident;
  }
  
  /**
   * A function consists of a sequence of instructions.
   */
  export interface Function {
    name: Ident;
    instrs: (Instruction | Label)[];
  }
  
  /**
   * A program consists of a set of functions, one of which must be named
   * "main".
   */
  export interface Program {
    functions: Function[];
  }

  export type PC = {function:string; index:number};

export class BaseInterpreter {
    env: Env;
    opDispatchTable: {[x:string] : (instr: Instruction) => void};
    pc: PC;
    program: Program;

    constructor(program: Program) {
        this.env = new Map();
        this.opDispatchTable = {
            "id": this.evalId,
            "add": this.evalAdd
        }
        this.program = program;
        this.pc = this.getEntryPoint();
    }

    getEntryPoint(): PC {
        return {function: "main", index: 0};
    }

    getFunction(functionName: Ident): Function | null {
        for (let func of this.program.functions) {
            if (func.name === functionName) {
                return func;
            }
        }
        return null
    }

    getInstruction(pc: PC): Instruction | Label | null {
        let func = this.getFunction(pc.function);
        if (func != null) {
            if (pc.index >= 0 && pc.index < func.instrs.length) {
                return func.instrs[pc.index];
            }
        }
        return null;
    }

    nextPC() {
        this.pc.index++;
    }

    jumpToLabel(label: Ident) {
        // Search for the label and transfer control.
        let func = this.getFunction(this.pc.function);
        if (func != null) {
            for (let i = 0; i < func.instrs.length; ++i) {
                let sLine = func.instrs[i];
                if ('label' in sLine && sLine.label === label) {
                    this.pc.index = i;
                    return;
                }
            }
            throw `label ${label} not found in function ${this.pc.function}`;
        } else {
            throw `PC function ${this.pc.function} does not exist`
        }

    }

    get(ident: Ident) {
        let val = this.env.get(ident);
        if (typeof val === 'undefined') {
            throw `undefined variable ${ident}`;
        }
        return val;
    }

    getSafeArg(instr: Instruction, index: number) {
        if (index >= instr.args.length) {
            throw `Index ${index} out of bounds for ${instr.op} with args ${instr.args}`;  
        }
        return instr.args[index];
    }

    getSafeArgVal(instr: Instruction, index: number) {
        return this.get(this.getSafeArg(instr, index));
    }

    getInt(instr: Instruction, index: number) {
        let val = this.getSafeArgVal(instr, index);
        if (typeof val !== 'bigint') {
          throw `${instr.op} argument ${index} must be a number`;
        }
        return val;
      }
      
    getBool(instr: Instruction, index: number) {
        let val = this.getSafeArgVal(instr, index);
        if (typeof val !== 'boolean') {
            throw `${instr.op} argument ${index} must be a boolean`;
        }
        return val;
    }

    getSafeDest(instr: Instruction) {
        if ('dest' in instr) {
            return instr.dest;
        }
        throw `Instruction ${instr} does not have a dest field`;
    }

    getSafeValue(instr: Instruction) {
        if ('value' in instr) {
            return instr.value;
        }
        throw `Instruction ${instr} does not have a value field`;
    }

    setDest(instr: Instruction, val: boolean | bigint) {
        this.env.set(this.getSafeDest(instr), val);
    }

    evalId(instr: Instruction) {
        let val = this.getSafeArgVal(instr, 0);
        this.env.set(instr.dest, val);
        this.nextPC();
    }

    evalNop(instr: Instruction) {
        this.nextPC();
    }

    evalConst(instr: Instruction) {
        let value: Value;
        // Ensure that JSON ints get represented appropriately.
        let instrValue = this.getSafeValue(instr);
        if (typeof instrValue === "number") {
          value = BigInt(instrValue);
        } else {
          value = instrValue;
        }
    
        this.setDest(instr, value);
        this.nextPC();
    }

    evalIntBinop(instr: Instruction, op: (x:bigint, y:bigint) => boolean | bigint) {
        let val = op(this.getInt(instr, 0), this.getInt(instr, 1));
        this.setDest(instr, val);
        this.nextPC();
    }

    evalAdd(instr: Instruction) {
        this.evalIntBinop(instr, (x, y) => x + y);
    }

    evalMul(instr: Instruction) {
        this.evalIntBinop(instr, (x, y) => x * y);
    }

    evalSub(instr: Instruction) {
        this.evalIntBinop(instr, (x, y) => x - y);
    }

    evalDiv(instr: Instruction) {
        this.evalIntBinop(instr, (x, y) => x / y);
    }

    evalLe(instr: Instruction) {
        this.evalIntBinop(instr, (x, y) => x <= y);
    }

    evalLt(instr: Instruction) {
        this.evalIntBinop(instr, (x, y) => x < y);
    }

    evalGt(instr: Instruction) {
        this.evalIntBinop(instr, (x, y) => x > y);
    }

    evalGe(instr: Instruction) {
        this.evalIntBinop(instr, (x, y) => x >= y);
    }

    evalEq(instr: Instruction) {
        this.evalIntBinop(instr, (x, y) => x === y);
    }

    evalNot(instr: Instruction) {
        let val = !this.getBool(instr, 0);
        this.setDest(instr, val);
        this.nextPC();
    }

    evalAnd(instr: Instruction) {
        let val = this.getBool(instr, 0) && this.getBool(instr, 1);
        this.setDest(instr, val);
        this.nextPC();
    }

    evalOr(instr: Instruction) {
        let val = this.getBool(instr, 0) || this.getBool(instr, 1);
        this.setDest(instr, val);
        this.nextPC();
    }

    evalPrint(instr: Instruction) {
        let values = instr.args.map(i => this.get(i).toString());
        console.log(...values);
        this.nextPC();
    }

    evalJmp(instr: Instruction) {
        let label = this.getSafeArg(instr, 0);
        this.jumpToLabel(label);
    }

    evalBr(instr: Instruction) {
        let cond = this.getBool(instr, 0);
        if (cond) {
            let label = this.getSafeArg(instr, 1);
            this.jumpToLabel(label);
        } else {
            let label = this.getSafeArg(instr, 2);
            this.jumpToLabel(label);
        }
    }

    evalRet(instr: Instruction) {
        this.pc.index = -1;
    }

    run() {
        while(true) {
            let nextInstr = this.getInstruction(this.pc);
            if (nextInstr === null) {
                // terminate
                break;
            } else if ("op" in nextInstr) {

                let dispatchFunc = this.opDispatchTable[nextInstr.op];
                if (dispatchFunc) {
                    dispatchFunc(nextInstr);
                } else {
                    throw `unhandled opcode ${(nextInstr as any).op}`;
                }
            } else {
                // label, just treat as nop
                this.nextPC();
            }
        }
    }
}


/**
 * Interpret an instruction in a given environment, possibly updating the
 * environment. If the instruction branches to a new label, return that label;
 * otherwise, return "next" to indicate that we should proceed to the next
 * instruction or "end" to terminate the function.
 */

async function main() {
  let prog = JSON.parse(await readStdin()) as Program;
  let interpreter = new BaseInterpreter(prog);
  interpreter.run();
}

// Make unhandled promise rejections terminate.
process.on('unhandledRejection', e => { throw e });

main();
