open! Core

type value = Int of int | Bool of bool [@@deriving sexp]

type typ = Int | Bool [@@deriving sexp]

type ident = string [@@deriving sexp]

type br_data = {var: ident; true_l: ident; false_l: ident} [@@deriving sexp]

type jmp_data = ident [@@deriving sexp]

type print_data = ident list [@@deriving sexp]

type bin_op_data = {dest: ident; arg_l: ident; arg_r: ident; typ: typ}
[@@deriving sexp]

type un_op_data = {dest: ident; arg: ident; typ: typ} [@@deriving sexp]

(* type id_data = {dest: ident; typ: typ; arg: ident} [@@deriving sexp] *)

type const_data = {dest: ident; value: value; typ: typ} [@@deriving sexp]

type operation =
  | Br of br_data
  | Jmp of jmp_data
  | Print of print_data
  | Ret
  | Id of un_op_data
  | Const of const_data
  | Nop
  | Add of bin_op_data
  | Mul of bin_op_data
  | Sub of bin_op_data
  | Div of bin_op_data
  | Eq of bin_op_data
  | Lt of bin_op_data
  | Gt of bin_op_data
  | Le of bin_op_data
  | Ge of bin_op_data
  | And of bin_op_data
  | Or of bin_op_data
  | Not of un_op_data
[@@deriving sexp]

type label = ident [@@deriving sexp]

type function_instruction = Label of label | Operation of operation
[@@deriving sexp]

type funct = {name: ident; instrs: function_instruction list} [@@deriving sexp]

type program = {functions: funct list} [@@deriving sexp]
