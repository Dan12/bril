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

let parse_string (str : json) : string option =
  match str with `String s -> Some s | _ -> None

let parse_args (args : json) : string list option =
  match args with
  | `List l -> List.map l ~f:parse_string |> Option.all
  | _ -> None

let parse_value (v : json) : value option =
  match v with `Int i -> Some (Int i) | `Bool b -> Some (Bool b) | _ -> None

let parse_instr (instr : json) : instr Or_error.t =
  match instr with
  | `Assoc a ->
      let find name parse =
        List.Assoc.find a ~equal:String.equal name
        |> Option.map ~f:parse |> Option.join
      in
      Or_error.return
        { dest= find "dest" parse_string
        ; op= find "op" parse_string
        ; typ= find "type" parse_string
        ; value= find "value" parse_value
        ; args= find "args" parse_args
        ; label= find "label" parse_string }
  | _ -> Or_error.error_s [%message "instruction is not an object"]

let parse_function (funct : json) : funct Or_error.t =
  match funct with
  | `Assoc [("instrs", `List instrs); ("name", `String name)]
   |`Assoc [("name", `String name); ("instrs", `List instrs)] ->
      let instrs = List.map instrs ~f:parse_instr |> Or_error.combine_errors in
      Or_error.map instrs ~f:(fun instrs -> {name; instrs})
  | _ ->
      Or_error.error_s [%message "Function is not object with name and instrs"]

let parse_program (program : json) : program Or_error.t =
  match program with
  | `Assoc [("functions", `List functs)] ->
      let functs =
        List.map functs ~f:parse_function |> Or_error.combine_errors
      in
      Or_error.map functs ~f:(fun functs -> {functions= functs})
  | _ -> Or_error.error_s [%message "No top level function list"]
