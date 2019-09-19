open! Core

module Data_type = struct
  type i64

  type i1

  type 'a ptr

  (* type 'a data_type = Int : i64 data_type | Bool : i1 data_type
   * 
   * type t = Any : 'a data_type -> t
   * 
   * let to_string (type a) (t : a data_type) =
   *   match t with Int -> "i64" | Bool -> "i1" *)
end

module Variable = struct
  type 'a t = string

  let create_fresh_var_gen current_vars =
    let i = ref 0 in
    let rec gen_fresh_var () =
      let cur_i = !i in
      incr i ;
      let var = "_v" ^ Int.to_string cur_i in
      if List.mem current_vars var ~equal:String.equal then gen_fresh_var ()
      else var
    in
    gen_fresh_var
end

(* module Const = struct
 *   type t = {value: int; typ: Data_type.t}
 * end *)

module Stack = struct
  let create num = (sprintf "%%stack = alloca i64, %d" num, "stack")
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

  let append_gen_ptr t ~gen_fresh base offset =
    let result_var = gen_fresh () in
    let instr =
      sprintf "%%%s = getelementptr inbounds i64, i64* %%%s, i64 %d" result_var
        base offset
    in
    t.instructions <- instr :: t.instructions ;
    result_var

  let append_load t ~gen_fresh ptr =
    let result_var = gen_fresh () in
    let instr = sprintf "%%%s = load i64, i64* %%%s" result_var ptr in
    t.instructions <- instr :: t.instructions ;
    result_var

  let append_store t ptr arg =
    let instr = sprintf "store i64 %%%s, i64* %%%s" ptr arg in
    t.instructions <- instr :: t.instructions

  let append_const t ~gen_fresh value =
    let result_var = gen_fresh () in
    let instr = sprintf "%%%s = i64 %d" result_var value in
    t.instructions <- instr :: t.instructions ;
    result_var

  let append_printi t arg =
    let instr = sprintf "call void @printi(i64 %%%s)" arg in
    t.instructions <- instr :: t.instructions

  let append_printb t arg =
    let instr = sprintf "call void @printb(i1 %%%s)" arg in
    t.instructions <- instr :: t.instructions

  let append_ret t =
    let instr = sprintf "ret i64 0" in
    t.instructions <- instr :: t.instructions

  let append_jmp t label =
    let instr = sprintf "br label %%%s" label in
    t.instructions <- instr :: t.instructions

  let append_br t true_l false_l arg =
    let instr =
      sprintf "br i1 %%%s, label %%%s, label %%%s" arg true_l false_l
    in
    t.instructions <- instr :: t.instructions

  let append_ne t ~gen_fresh arg1 arg2 =
    let result_var = gen_fresh () in
    let instr = sprintf "%%%s = icmp ne i64 %%%s, %%%s" result_var arg1 arg2 in
    t.instructions <- instr :: t.instructions ;
    result_var

  let append_add t ~gen_fresh arg1 arg2 =
    let result_var = gen_fresh () in
    let instr = sprintf "%%%s = add i64 %%%s, %%%s" result_var arg1 arg2 in
    t.instructions <- instr :: t.instructions ;
    result_var
end
