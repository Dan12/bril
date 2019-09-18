open! Core
open! Bril_v2

let transform_v2 (op : Bril.operation) : any_op =
  match op with
  | Br {var; true_l; false_l} ->
      Any {op= Br; ex= Effect_op {op= Br; args= Br {var; true_l; false_l}}}
  | Jmp label -> Any {op= Jmp; ex= Effect_op {op= Jmp; args= Jmp label}}
  | Print args -> Any {op= Print; ex= Effect_op {op= Print; args= Print args}}
  | Ret -> Any {op= Ret; ex= Effect_op {op= Ret; args= Ret}}
  | Const {dest; value; typ} ->
      Any
        {op= Const; ex= Mutation_op {op= Const; dest; typ; ex= Const_op value}}
  | Add {dest; arg_l; arg_r; typ} ->
      Any
        { op= Add
        ; ex=
            Mutation_op
              { op= Add
              ; dest
              ; typ
              ; ex= Value_op {op= Add; args= Bin_op {arg_l; arg_r}} } }
  | Mul {dest; arg_l; arg_r; typ} ->
      Any
        { op= Mul
        ; ex=
            Mutation_op
              { op= Mul
              ; dest
              ; typ
              ; ex= Value_op {op= Mul; args= Bin_op {arg_l; arg_r}} } }
  | Sub {dest; arg_l; arg_r; typ} ->
      Any
        { op= Sub
        ; ex=
            Mutation_op
              { op= Sub
              ; dest
              ; typ
              ; ex= Value_op {op= Sub; args= Bin_op {arg_l; arg_r}} } }
  | Div {dest; arg_l; arg_r; typ} ->
      Any
        { op= Div
        ; ex=
            Mutation_op
              { op= Div
              ; dest
              ; typ
              ; ex= Value_op {op= Div; args= Bin_op {arg_l; arg_r}} } }
  | Eq {dest; arg_l; arg_r; typ} ->
      Any
        { op= Eq
        ; ex=
            Mutation_op
              { op= Eq
              ; dest
              ; typ
              ; ex= Value_op {op= Eq; args= Bin_op {arg_l; arg_r}} } }
  | Lt {dest; arg_l; arg_r; typ} ->
      Any
        { op= Lt
        ; ex=
            Mutation_op
              { op= Lt
              ; dest
              ; typ
              ; ex= Value_op {op= Lt; args= Bin_op {arg_l; arg_r}} } }
  | Gt {dest; arg_l; arg_r; typ} ->
      Any
        { op= Gt
        ; ex=
            Mutation_op
              { op= Gt
              ; dest
              ; typ
              ; ex= Value_op {op= Gt; args= Bin_op {arg_l; arg_r}} } }
  | Le {dest; arg_l; arg_r; typ} ->
      Any
        { op= Le
        ; ex=
            Mutation_op
              { op= Le
              ; dest
              ; typ
              ; ex= Value_op {op= Le; args= Bin_op {arg_l; arg_r}} } }
  | Ge {dest; arg_l; arg_r; typ} ->
      Any
        { op= Ge
        ; ex=
            Mutation_op
              { op= Ge
              ; dest
              ; typ
              ; ex= Value_op {op= Ge; args= Bin_op {arg_l; arg_r}} } }
  | And {dest; arg_l; arg_r; typ} ->
      Any
        { op= And
        ; ex=
            Mutation_op
              { op= And
              ; dest
              ; typ
              ; ex= Value_op {op= And; args= Bin_op {arg_l; arg_r}} } }
  | Or {dest; arg_l; arg_r; typ} ->
      Any
        { op= Or
        ; ex=
            Mutation_op
              { op= Or
              ; dest
              ; typ
              ; ex= Value_op {op= Or; args= Bin_op {arg_l; arg_r}} } }
  | Not {dest; arg; typ} ->
      Any
        { op= Not
        ; ex=
            Mutation_op
              {op= Not; dest; typ; ex= Value_op {op= Not; args= Un_op arg}} }
  | Id {dest; arg} -> Any {op= Id; ex= Id_op {dest; arg}}
  | Nop -> Any {op= Nop; ex= Nop_op}

let transform_instr (instr : Bril.function_instruction) : function_instruction
    =
  match instr with
  | Label label -> Label label
  | Operation op -> Operation (transform_v2 op)

let transform_function (funct : Bril.funct) : funct =
  {name= funct.name; instrs= List.map funct.instrs ~f:transform_instr}

let transform_program (program : Bril.program) : program =
  {functions= List.map program.functions ~f:transform_function}
