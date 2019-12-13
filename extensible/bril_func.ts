import * as bril from './bril_base';

/**
 * An operation that calls another Bril function.
 */
export interface CallOperation {
  op: "call";
  args: bril.Ident[];
}

/**
 * An operation that calls another Bril function.
 */
export type Operation = CallOperation;

export type Instruction = Operation;

/*
 * An argument has a name and a type.
 */
export interface Argument {
  name: bril.Ident;
  type: bril.Type;
}

/**
 * A function consists of a sequence of instructions.
 */
 export interface Function {
  name: bril.Ident;
  args: Argument[];
  instrs: (Instruction | bril.Label)[];
}