import { BaseInstruction, BaseFunction, BaseProgram } from './util';
import { PC } from './brili_base'


type evalFunc<A, P, F, I> = (instr: I, programState: P, functionState: F) => A;

type actionHandler<A, P, FS, I extends BaseInstruction, F extends BaseFunction<I>> = (action: A, pc: PC<I, F>, programState: P, functionState: FS) => PC<I, F>;

interface MinProgramState<F> {
  currentFunctionState: F
}

export class Composer<A, P extends MinProgramState<FS>, FS, I extends BaseInstruction, F extends BaseFunction<I>> {
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

  eval(pc: PC<I, F>, programState: P) {
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

  evalProg<Prog extends BaseProgram<I,F>>(prog: Prog) {
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