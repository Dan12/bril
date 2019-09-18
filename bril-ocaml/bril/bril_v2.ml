open! Core

type value = Bril.value

type typ = Bril.typ

type ident = Bril.ident

type br_data = {var: ident; true_l: ident; false_l: ident}

type jmp_data = ident

type print_data = ident list

type bin_op_data = {arg_l: ident; arg_r: ident}

type un_op_data = ident

type id_data = {dest: ident; arg: ident}

type const_data = value

type _ effect_op_data =
  | Jmp : jmp_data -> [`Jmp] effect_op_data
  | Br : br_data -> [`Br] effect_op_data
  | Ret : [`Ret] effect_op_data
  | Print : print_data -> [`Print] effect_op_data

type _ effect_opcode =
  | Jmp : [`Jmp] effect_opcode
  | Br : [`Br] effect_opcode
  | Ret : [`Ret] effect_opcode
  | Print : [`Print] effect_opcode

type 'a effect_op = {op: 'a effect_opcode; args: 'a effect_op_data}

type _ bin_op_v2_ex =
  | Int_op : [< `Add | `Mul | `Sub | `Div] bin_op_v2_ex
  | Bool_op : [< `Eq | `Lt | `Gt | `Le | `Ge | `And | `Or] bin_op_v2_ex

type _ binop_opcode =
  | Add : [`Add] binop_opcode
  | Mul : [`Mul] binop_opcode
  | Sub : [`Sub] binop_opcode
  | Div : [`Div] binop_opcode
  | Eq : [`Eq] binop_opcode
  | Lt : [`Lt] binop_opcode
  | Gt : [`Gt] binop_opcode
  | Le : [`Le] binop_opcode
  | Ge : [`Ge] binop_opcode
  | And : [`And] binop_opcode
  | Or : [`Or] binop_opcode

type 'a bin_op_v2 =
  {op: 'a binop_opcode; arg_l: ident; arg_r: ident; ex: 'a bin_op_v2_ex}

type _ value_op_data =
  | Bin_op :
      bin_op_data
      -> [< `Add
         | `Mul
         | `Sub
         | `Div
         | `Eq
         | `Lt
         | `Gt
         | `Le
         | `Ge
         | `And
         | `Or ]
         value_op_data
  | Un_op : un_op_data -> [< `Not] value_op_data

type _ value_opcode =
  | Add : [`Add] value_opcode
  | Mul : [`Mul] value_opcode
  | Sub : [`Sub] value_opcode
  | Div : [`Div] value_opcode
  | Eq : [`Eq] value_opcode
  | Lt : [`Lt] value_opcode
  | Gt : [`Gt] value_opcode
  | Le : [`Le] value_opcode
  | Ge : [`Ge] value_opcode
  | And : [`And] value_opcode
  | Or : [`Or] value_opcode
  | Not : [`Not] value_opcode

type 'a value_op = {op: 'a value_opcode; args: 'a value_op_data}

type _ mutation_op_ex =
  | Value_op : 'a value_op -> 'a mutation_op_ex
  | Const_op : const_data -> [`Const] mutation_op_ex

type _ mut_opcode =
  | Const : [`Const] mut_opcode
  | Add : [`Add] mut_opcode
  | Mul : [`Mul] mut_opcode
  | Sub : [`Sub] mut_opcode
  | Div : [`Div] mut_opcode
  | Eq : [`Eq] mut_opcode
  | Lt : [`Lt] mut_opcode
  | Gt : [`Gt] mut_opcode
  | Le : [`Le] mut_opcode
  | Ge : [`Ge] mut_opcode
  | And : [`And] mut_opcode
  | Or : [`Or] mut_opcode
  | Not : [`Not] mut_opcode

type 'a mutation_op =
  {dest: ident; typ: typ; op: 'a mut_opcode; ex: 'a mutation_op_ex}

type _ op_ex =
  | Effect_op : 'a effect_op -> 'a op_ex
  | Mutation_op : 'a mutation_op -> 'a op_ex
  | Nop_op : [`Nop] op_ex
  | Id_op : id_data -> [`Id] op_ex

type _ opcode =
  | Jmp : [`Jmp] opcode
  | Br : [`Br] opcode
  | Ret : [`Ret] opcode
  | Print : [`Print] opcode
  | Const : [`Const] opcode
  | Add : [`Add] opcode
  | Mul : [`Mul] opcode
  | Sub : [`Sub] opcode
  | Div : [`Div] opcode
  | Eq : [`Eq] opcode
  | Lt : [`Lt] opcode
  | Gt : [`Gt] opcode
  | Le : [`Le] opcode
  | Ge : [`Ge] opcode
  | And : [`And] opcode
  | Or : [`Or] opcode
  | Not : [`Not] opcode
  | Nop : [`Nop] opcode
  | Id : [`Id] opcode

type 'a operation = {op: 'a opcode; ex: 'a op_ex}

type any_op = Any : 'a operation -> any_op

type label = ident

type function_instruction = Label of label | Operation of any_op

type funct = {name: ident; instrs: function_instruction list}

type program = {functions: funct list}
