open! Core

module Data_type = struct
  type i64

  type i1

  type 'a ptr = P of 'a

  type strct

  type _ t =
    | Int : i64 t
    | Bool : i1 t
    | Ptr : 'a t -> 'a ptr t
    | Strct : packed list -> strct t

  and packed = Packed : 'a t -> packed

  let pack t = Packed t

  let rec aux_to_string (Packed t) =
    match t with
    | Int -> "i64"
    | Bool -> "i1"
    | Ptr d -> sprintf "%s*" (aux_to_string (pack d))
    | Strct typs ->
        sprintf "{ %s }"
          ( List.map typs ~f:(fun typ -> aux_to_string typ)
          |> String.concat ~sep:"," )

  let to_string t = aux_to_string (pack t)
end

module Variable = struct
  type 'a t = {name: string; typ: 'a Data_type.t}

  let create_fresh_var_gen current_vars =
    let i = ref 0 in
    let rec gen_fresh_var typ =
      let cur_i = !i in
      incr i ;
      let var = "_v" ^ Int.to_string cur_i in
      if List.mem current_vars var ~equal:String.equal then gen_fresh_var typ
      else {name= var; typ}
    in
    gen_fresh_var
end

(* module Spec_var : sig
 *   val spec : 'a Data_type.t -> 'b Variable.t -> 'a Variable.t
 * end = struct
 *   let spec (_ : 'a Data_type.t) (var : 'b Variable.t) =
 *     let open Variable in
 *     {name= var.name; typ= var.typ}
 * end *)

module Gen_Fresh (Vars : sig
  val vars : string list
end) =
struct
  let i = ref 0

  let rec gen_fresh typ =
    let open Variable in
    let cur_i = !i in
    incr i ;
    let var = "_v" ^ Int.to_string cur_i in
    if List.mem Vars.vars var ~equal:String.equal then gen_fresh typ
    else {name= var; typ}
end

module Stack = struct
  type t = Data_type.strct Variable.t

  let create ~var_typ_list =
    {Variable.name= "stack"; typ= Data_type.Strct var_typ_list}

  let gen_init_str (t : t) =
    sprintf "%%%s = alloca %s" t.name
      (Data_type.aux_to_string (Data_type.pack t.typ))
end

module Block = struct
  type t = {label: string; mutable instructions: string list}

  let create name = {label= name; instructions= []}

  let to_string t =
    sprintf {|
%s:
  %s
|} t.label
      (List.rev t.instructions |> String.concat ~sep:"\n")

  let append_gen_ptr t ~gen_fresh ~base ~offset =
    let open Variable in
    let result_var = gen_fresh (Data_type.Ptr Data_type.Int) in
    let instr =
      sprintf "%%%s = getelementptr inbounds i64, i64* %%%s, i64 %d"
        result_var.name base.name offset
    in
    t.instructions <- instr :: t.instructions ;
    result_var

  let append_gen_struct_ptr t ~gen_fresh ~base ~offset =
    let open Variable in
    let result_var = gen_fresh (Data_type.Ptr Data_type.Int) in
    let instr =
      sprintf "%%%s = getelementptr inbounds i64, i64* %%%s, i64 0, i64 %d"
        result_var.name base.name offset
    in
    t.instructions <- instr :: t.instructions ;
    result_var

  let append_load t ~gen_fresh ~ptr =
    let open Variable in
    let result_var = gen_fresh Data_type.Int in
    let instr =
      sprintf "%%%s = load i64, i64* %%%s" result_var.name ptr.name
    in
    t.instructions <- instr :: t.instructions ;
    result_var

  let append_store t ~ptr ~arg =
    let open Variable in
    let instr = sprintf "store i64 %%%s, i64* %%%s" ptr.name arg.name in
    t.instructions <- instr :: t.instructions

  let append_const t ~gen_fresh ~value =
    let open Variable in
    let result_var = gen_fresh Data_type.Int in
    let instr = sprintf "%%%s = i64 %d" result_var.name value in
    t.instructions <- instr :: t.instructions ;
    result_var

  let append_printi t ~arg =
    let open Variable in
    let instr = sprintf "call void @printi(i64 %%%s)" arg.name in
    t.instructions <- instr :: t.instructions

  let append_printb t ~arg =
    let open Variable in
    let instr = sprintf "call void @printb(i1 %%%s)" arg.name in
    t.instructions <- instr :: t.instructions

  let append_ret t =
    let instr = sprintf "ret i64 0" in
    t.instructions <- instr :: t.instructions

  let append_jmp t ~label =
    let instr = sprintf "br label %%%s" label in
    t.instructions <- instr :: t.instructions

  let append_br t ~true_l ~false_l ~arg =
    let open Variable in
    let instr =
      sprintf "br i1 %%%s, label %%%s, label %%%s" arg.name true_l false_l
    in
    t.instructions <- instr :: t.instructions

  let append_ne t ~gen_fresh ~arg1 ~arg2 =
    let open Variable in
    let result_var = gen_fresh Data_type.Bool in
    let instr =
      sprintf "%%%s = icmp ne i64 %%%s, %%%s" result_var.name arg1.name
        arg2.name
    in
    t.instructions <- instr :: t.instructions ;
    result_var

  let append_add t ~gen_fresh ~arg1 ~arg2 =
    let open Variable in
    let result_var = gen_fresh Data_type.Int in
    let instr =
      sprintf "%%%s = add i64 %%%s, %%%s" result_var.name arg1.name arg2.name
    in
    t.instructions <- instr :: t.instructions ;
    result_var
end
