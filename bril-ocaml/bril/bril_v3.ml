open! Core

type value = Int of int | Bool of bool [@@deriving sexp]

type typ = Int | Bool [@@deriving sexp]

type ident = string [@@deriving sexp]

type bin_op = Add | Sub [@@deriving sexp]

type operation =
  | Bin_op of {op: bin_op; dest: ident; arg_l: ident; arg_r: ident; typ: typ}
  | Br of {var: ident; true_l: ident; false_l: ident}
  | Jmp of ident
  | Print of ident list
  | Ret
  | Nop
  | Const of {dest: ident; value: value; typ: typ}
  | Not of {dest: ident; arg: ident; typ: typ}
[@@deriving sexp]

type label = ident [@@deriving sexp]

type function_instruction = Label of label | Operation of operation
[@@deriving sexp]

type funct = {name: ident; instrs: function_instruction list} [@@deriving sexp]

type program = {functions: funct list} [@@deriving sexp]
