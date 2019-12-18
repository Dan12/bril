import { BaseInstruction, BaseFunction, BaseAction } from './util';

export type PC<I extends BaseInstruction, F extends BaseFunction<I>> = { function: F; index: number };

type evalFunc<A, P, FS, I> = (instr: I, programState: P, functionState: FS) => A;

type actionHandler<A, P, FS, I extends BaseInstruction, F extends BaseFunction<I>> = (action: A, pc: PC<I, F>, programState: P, functionState: FS) => PC<I, F>;

export abstract class Extension<A extends BaseAction, P, FS, I extends BaseInstruction, F extends BaseFunction<I>, A_comp extends BaseAction, P_comp extends P, FS_comp extends FS, I_comp extends BaseInstruction, F_comp extends BaseFunction<I_comp>> {

  baseEval: evalFunc<A_comp, P_comp, FS_comp, I_comp>;
  baseActionHandler: actionHandler<A_comp, P_comp, FS_comp, I_comp, F_comp>;

  constructor(baseEval: evalFunc<A_comp, P_comp, FS_comp, I_comp>, baseActionHandler: actionHandler<A_comp, P_comp, FS_comp, I_comp, F_comp>) {
    this.baseEval = baseEval;
    this.baseActionHandler = baseActionHandler;
  }

  abstract evalExtInstr(instr: I, programState: P, functionState: FS): A | A_comp;

  abstract isExtInstr(instr: { op: string }): instr is I;

  evalInstr(instr: I | I_comp, programState: P_comp, functionState: FS_comp): A | A_comp {
    if (this.isExtInstr(instr)) {
      return this.evalExtInstr(instr, programState, functionState);
    } else {
      return this.baseEval(instr, programState, functionState);
    }
  }

  abstract handleExtAction(action: A, pc: PC<I_comp, F_comp>, programState: P_comp, functionState: FS_comp): PC<I_comp, F_comp>;

  abstract isExtAction(action: { type: string }): action is A;

  evalAction(action: A | A_comp, pc: PC<I_comp, F_comp>, programState: P_comp, functionState: FS_comp): PC<I_comp, F_comp> {
    if (this.isExtAction(action)) {
      return this.handleExtAction(action, pc, programState, functionState);
    } else {
      return this.baseActionHandler(action, pc, programState, functionState);
    }
  }
}

export abstract class InstrExtension<A extends BaseAction, P, FS, I extends BaseInstruction, F extends BaseFunction<I>, A_comp extends BaseAction, P_comp extends P, FS_comp extends FS, I_comp extends BaseInstruction, F_comp extends BaseFunction<I_comp>> extends Extension<A, P, FS, I, F, A_comp, P_comp, FS_comp, I_comp, F_comp> {
  handleExtAction(action: never, pc: PC<I_comp, F_comp>, programState: P_comp, functionState: FS_comp): PC<I_comp, F_comp> {
    throw 'should never happen';
  }

  isExtAction(action: { type: string }): action is never {
    return false;
  }
}