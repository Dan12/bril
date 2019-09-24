open! Core
open! Bril_lib.Bril
open! Yojson.Basic

let gen_type (typ : typ) : json =
  match typ with Int -> `String "int" | Bool -> `String "bool"

let gen_value (value : value) : json =
  match value with Int i -> `Int i | Bool b -> `Bool b

let gen_args (args : string list) : json =
  `List (List.map args ~f:(fun arg -> `String arg))

let gen_op (op : operation) : json =
  let op, data =
    match op with
    | Br {var; true_l; false_l} ->
        ("br", [("args", gen_args [var; true_l; false_l])])
    | Jmp label -> ("jmp", [("args", gen_args [label])])
    | Print args -> ("print", [("args", gen_args args)])
    | Ret -> ("ret", [])
    | Id {dest; typ; arg} ->
        ( "id"
        , [ ("dest", `String dest)
          ; ("type", gen_type typ)
          ; ("args", gen_args [arg]) ] )
    | Const {dest; value; typ} ->
        ( "const"
        , [ ("dest", `String dest)
          ; ("value", gen_value value)
          ; ("type", gen_type typ) ] )
    | Nop -> ("nop", [])
    | Add {dest; arg_l; arg_r; typ} ->
        ( "add"
        , [ ("dest", `String dest)
          ; ("args", gen_args [arg_l; arg_r])
          ; ("type", gen_type typ) ] )
    | Mul {dest; arg_l; arg_r; typ} ->
        ( "mul"
        , [ ("dest", `String dest)
          ; ("args", gen_args [arg_l; arg_r])
          ; ("type", gen_type typ) ] )
    | Sub {dest; arg_l; arg_r; typ} ->
        ( "sub"
        , [ ("dest", `String dest)
          ; ("args", gen_args [arg_l; arg_r])
          ; ("type", gen_type typ) ] )
    | Div {dest; arg_l; arg_r; typ} ->
        ( "div"
        , [ ("dest", `String dest)
          ; ("args", gen_args [arg_l; arg_r])
          ; ("type", gen_type typ) ] )
    | Eq {dest; arg_l; arg_r; typ} ->
        ( "eq"
        , [ ("dest", `String dest)
          ; ("args", gen_args [arg_l; arg_r])
          ; ("type", gen_type typ) ] )
    | Lt {dest; arg_l; arg_r; typ} ->
        ( "lt"
        , [ ("dest", `String dest)
          ; ("args", gen_args [arg_l; arg_r])
          ; ("type", gen_type typ) ] )
    | Gt {dest; arg_l; arg_r; typ} ->
        ( "gt"
        , [ ("dest", `String dest)
          ; ("args", gen_args [arg_l; arg_r])
          ; ("type", gen_type typ) ] )
    | Le {dest; arg_l; arg_r; typ} ->
        ( "le"
        , [ ("dest", `String dest)
          ; ("args", gen_args [arg_l; arg_r])
          ; ("type", gen_type typ) ] )
    | Ge {dest; arg_l; arg_r; typ} ->
        ( "ge"
        , [ ("dest", `String dest)
          ; ("args", gen_args [arg_l; arg_r])
          ; ("type", gen_type typ) ] )
    | And {dest; arg_l; arg_r; typ} ->
        ( "and"
        , [ ("dest", `String dest)
          ; ("args", gen_args [arg_l; arg_r])
          ; ("type", gen_type typ) ] )
    | Or {dest; arg_l; arg_r; typ} ->
        ( "or"
        , [ ("dest", `String dest)
          ; ("args", gen_args [arg_l; arg_r])
          ; ("type", gen_type typ) ] )
    | Not {dest; arg; typ} ->
        ( "not"
        , [ ("dest", `String dest)
          ; ("args", gen_args [arg])
          ; ("type", gen_type typ) ] )
  in
  `Assoc (("op", `String op) :: data)

let gen_instr (instr : function_instruction) : json =
  match instr with
  | Label label -> `Assoc [("label", `String label)]
  | Operation op -> gen_op op

let gen_funct (funct : funct) : json =
  `Assoc
    [ ("instrs", `List (List.map funct.instrs ~f:gen_instr))
    ; ("name", `String funct.name) ]

let gen_program (program : program) : json =
  `Assoc [("functions", `List (List.map program.functions ~f:gen_funct))]
