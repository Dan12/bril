import * as bril_base from './bril_base';

export type Ident = bril_base.Ident;
export type Type = bril_base.Type;

/**
 * Record types.
 */
export interface RecordType {
  [field: string]: Type | Ident;
}

export interface RecordAccess {
  op: "access";
  args: Ident[];
  dest: Ident;
  type: Type;
}

/**
 * An operation that produces a record value and places its result in the
 * destination variable.
 */
export interface RecordValue {
  op: "recordinst";
  fields: {[index: string]: Ident};
  dest: Ident;
  type: Type;
}

/**
 * An instruction that instantiates a record and places it into a variable.
 */
export interface RecordDef {
  op: "recorddef";
  recordname: Ident;
  fields: RecordType;
}

/**
 * An operation that produces a record value from an existing record and
 * places its result in the destination variable.
 */
export interface RecordWith {
  op: "recordwith";
  src: Ident;
  fields: {[index: string]: Ident};
  dest: Ident;
  type: Type;
}

/**
 * RecordOperations take arguments, which come from previously-assigned
 * identifiers, and initializes a record with them.
 */
export type RecordOperation = RecordValue | RecordWith;

export type Operation = RecordOperation | RecordDef | RecordAccess;

export type Instruction = Operation;