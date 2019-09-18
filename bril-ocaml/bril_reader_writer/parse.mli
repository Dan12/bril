open! Core
open! Yojson.Basic

type value = Int of int | Bool of bool [@@deriving sexp]

type instr =
  { dest: string option
  ; op: string option
  ; typ: string option
  ; value: value option
  ; args: string list option
  ; label: string option }
[@@deriving sexp]

type funct = {name: string; instrs: instr list} [@@deriving sexp]

type program = {functions: funct list} [@@deriving sexp]

val parse_program : json -> program Or_error.t
(* val gen_program : program -> json *)
