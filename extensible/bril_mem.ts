import * as bril_base from './bril_base';

export type Type = bril_base.Type | "ptr";

/**
 * The types to which a pointer may be pointing;
 */
export type PointerType = {
  "ptr": Type | PointerType;
}

export interface PointerEffectOperation {
  op: "store" | "free";
  args: bril_base.Ident[];
}

export interface PointerValueOperation {
  op: "load" | "ptradd";
  args: bril_base.Ident[];
  dest: bril_base.Ident;
  type: Type;
}

export interface PointerAllocOperation {
  op: "alloc";
  args: bril_base.Ident[];
  dest: bril_base.Ident;
  type: PointerType;
}

export type Operation = PointerEffectOperation | PointerValueOperation | PointerAllocOperation;

export type Instruction = Operation;