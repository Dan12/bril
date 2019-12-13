// import * as bril from './bril_base';

// /**
//  * An operation that calls another Bril function which has a return type and 
//  * stores the result in the destination variable.
//  */
// export interface ValueCallOperation {
//   op: "call";
//   name: Ident;
//   args: Ident[];
//   dest: Ident;
//   type: Type;
// }

// /**
//  * An operation that calls another Bril function with a void return type.
//  */
// export interface EffectCallOperation {
//   op: "call";
//   name: Ident;
//   args: Ident[];
// }

// /**
//  * An operation that calls another Bril function.
//  */
// export type CallOperation = ValueCallOperation | EffectCallOperation;


// export type Operation = bril.Operation | CallOperation

// export type ValueInstruction = bril.ValueInstruction | ValueCallOperation;

// /**
//  * The valid opcode for call operations.
//  */
// export type CallOpCode = CallOperation["op"];

// export type OpCode = bril.OpCode | CallOpCode;

// /*
//  * An argument has a name and a type.
//  */
// export interface Argument {
//   name: Ident;
//   type: Type;
// }

// export type Instruction = bril.Instruction | ;

// /**
//  * A function consists of a sequence of instructions.
//  */
//  export interface Function {
//   name: Ident;
//   args: Argument[];
//   instrs: (Instruction | bril.Label)[];
//   type?: Type;
// }

// /**
//  * A program consists of a set of functions, one of which must be named
//  * "main".
//  */
// export interface Program {
//   functions: Function[];
// }