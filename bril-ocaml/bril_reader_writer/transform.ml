open! Core
open! Bril_lib.Bril

let transform_typ (typ : string) : typ Or_error.t =
  match typ with
  | "int" -> Or_error.return Int
  | "bool" -> Or_error.return Bool
  | _ -> Or_error.error_s [%message "Unsupported type"]

let transform_value (value : Parse.value) : value =
  match value with Parse.Int i -> Int i | Parse.Bool b -> Bool b

let transform_binop (instr : Parse.instr) : bin_op_data Or_error.t =
  match (instr.dest, instr.args, instr.typ) with
  | Some dest, Some [arg_l; arg_r], Some typ ->
      Or_error.map (transform_typ typ) ~f:(fun typ -> {dest; arg_l; arg_r; typ})
  | _ ->
      Or_error.error_s [%message "Incorrect data format for binary opartion"]

let transform_unop (instr : Parse.instr) : un_op_data Or_error.t =
  match (instr.dest, instr.args, instr.typ) with
  | Some dest, Some [arg], Some typ ->
      Or_error.map (transform_typ typ) ~f:(fun typ -> {dest; arg; typ})
  | _ -> Or_error.error_s [%message "Incorrect data format for unary opartion"]

let transform_br (instr : Parse.instr) : br_data Or_error.t =
  match instr.args with
  | Some [var; true_l; false_l] -> Or_error.return {var; true_l; false_l}
  | _ ->
      Or_error.error_s [%message "Incorrect data format for branch operation"]

let transform_jmp (instr : Parse.instr) : jmp_data Or_error.t =
  match instr.args with
  | Some [label] -> Or_error.return label
  | _ -> Or_error.error_s [%message "Incorrect data format for jump operation"]

let transform_print (instr : Parse.instr) : print_data Or_error.t =
  match instr.args with
  | Some elts -> Or_error.return elts
  | _ ->
      Or_error.error_s [%message "Incorrect data format for print operation"]

let transform_id (instr : Parse.instr) : id_data Or_error.t =
  match (instr.dest, instr.args) with
  | Some dest, Some [arg] -> Or_error.return {dest; arg}
  | _ -> Or_error.error_s [%message "Incorrect data format for id operation"]

let transform_const (instr : Parse.instr) : const_data Or_error.t =
  match (instr.dest, instr.value, instr.typ) with
  | Some dest, Some value, Some typ ->
      Or_error.map (transform_typ typ) ~f:(fun typ ->
          {dest; value= transform_value value; typ} )
  | _ ->
      Or_error.error_s [%message "Incorrect data format for const operation"]

let transform_operation (instr : Parse.instr) : operation Or_error.t =
  match instr.op with
  | Some op -> (
    match op with
    | "nop" -> Or_error.return Nop
    | "ret" -> Or_error.return Ret
    | "print" ->
        Or_error.map (transform_print instr) ~f:(fun data -> Print data)
    | "br" -> Or_error.map (transform_br instr) ~f:(fun data -> Br data)
    | "jmp" -> Or_error.map (transform_jmp instr) ~f:(fun data -> Jmp data)
    | "id" -> Or_error.map (transform_id instr) ~f:(fun data -> Id data)
    | "const" ->
        Or_error.map (transform_const instr) ~f:(fun data -> Const data)
    | "add" -> Or_error.map (transform_binop instr) ~f:(fun data -> Add data)
    | "mul" -> Or_error.map (transform_binop instr) ~f:(fun data -> Mul data)
    | "sub" -> Or_error.map (transform_binop instr) ~f:(fun data -> Sub data)
    | "div" -> Or_error.map (transform_binop instr) ~f:(fun data -> Div data)
    | "eq" -> Or_error.map (transform_binop instr) ~f:(fun data -> Eq data)
    | "lt" -> Or_error.map (transform_binop instr) ~f:(fun data -> Lt data)
    | "gt" -> Or_error.map (transform_binop instr) ~f:(fun data -> Gt data)
    | "le" -> Or_error.map (transform_binop instr) ~f:(fun data -> Le data)
    | "ge" -> Or_error.map (transform_binop instr) ~f:(fun data -> Ge data)
    | "and" -> Or_error.map (transform_binop instr) ~f:(fun data -> And data)
    | "or" -> Or_error.map (transform_binop instr) ~f:(fun data -> Or data)
    | "not" -> Or_error.map (transform_unop instr) ~f:(fun data -> Not data)
    | _ -> Or_error.error_s [%message "Unimplemented op code"] )
  | None -> Or_error.error_s [%message "Instruction had no op code"]

let transform_instr (instr : Parse.instr) : function_instruction Or_error.t =
  match instr.label with
  | Some label -> Or_error.return (Label label)
  | None -> Or_error.map (transform_operation instr) ~f:(fun op -> Operation op)

let transform_function (funct : Parse.funct) : funct Or_error.t =
  let instrs = List.map funct.instrs ~f:transform_instr |> Or_error.all in
  Or_error.map instrs ~f:(fun instrs -> {name= funct.name; instrs})

let transform_program (program : Parse.program) : program Or_error.t =
  let functions =
    List.map program.functions ~f:transform_function |> Or_error.all
  in
  Or_error.map functions ~f:(fun functions -> {functions})
