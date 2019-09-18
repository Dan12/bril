open! Core
open! Bril_lib.Bril_v2
open! Basic_block_lib.Basic_block_v2

let collect_variables (instrs : function_instruction list) : ident list =
  List.fold instrs ~init:[] ~f:(fun vars instr ->
      match instr with
      | Label _ -> vars
      | Operation op -> (
        match op with
        | Any {ex= Mutation_op {dest; _}; _}
          when not (List.mem vars dest ~equal:String.equal) ->
            dest :: vars
        | Any {ex= Id_op {dest; _}; _}
          when not (List.mem vars dest ~equal:String.equal) ->
            dest :: vars
        | _ -> vars ) )

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

let gen_load_from_stack gen_fresh (var_map : int String.Map.t) var =
  let ptr_var = gen_fresh () in
  let result_var = gen_fresh () in
  match Map.find var_map var with
  | None -> ("", result_var)
  | Some idx ->
      ( sprintf
          {|
  %%%s = getelementptr inbounds i64, i64* %%stack, i64 %d
  %%%s = load i64, i64* %%%s
|}
          ptr_var idx result_var ptr_var
      , result_var )

let gen_store_const_to_stack gen_fresh (var_map : int String.Map.t) var const =
  let ptr_var = gen_fresh () in
  match Map.find var_map var with
  | None -> ""
  | Some idx ->
      sprintf
        {|
 %%%s = getelementptr inbounds i64, i64* %%stack, i64 %d
 store i64 %d, i64* %%%s
|}
        ptr_var idx const ptr_var

let gen_store_var_to_stack gen_fresh (var_map : int String.Map.t) var store_var
    =
  let ptr_var = gen_fresh () in
  match Map.find var_map var with
  | None -> ""
  | Some idx ->
      sprintf
        {|
 %%%s = getelementptr inbounds i64, i64* %%stack, i64 %d
 store i64 %%%s, i64* %%%s
|}
        ptr_var idx store_var ptr_var

let gen_value (value : value) =
  match value with Int i -> i | Bool b -> if b then 1 else 0

let gen_op_str gen_fresh (var_map : int String.Map.t) (op : any_op) =
  let (Any op) = op in
  match op with
  | {op= Jmp; ex= Effect_op {args= Jmp label; _}} ->
      sprintf "br label %%%s" label
  | {op= Ret; _} -> sprintf "ret i64 0"
  | {op= Print; ex= Effect_op {args= Print args; _}} ->
      let arg_prints =
        List.map args ~f:(fun arg ->
            let load_str, result_var =
              gen_load_from_stack gen_fresh var_map arg
            in
            sprintf {|
%s
call void @printi(i64 %%%s)
|} load_str result_var )
      in
      sprintf "%s" (String.concat arg_prints ~sep:"\n")
  | {op= Br; ex= Effect_op {args= Br {var; true_l; false_l}; _}} ->
      let load_str, result_var = gen_load_from_stack gen_fresh var_map var in
      let cmp_var = gen_fresh () in
      sprintf
        {|
%s
%%%s = icmp ne i64 %%%s, 0
br i1 %%%s, label %%%s, label %%%s
|}
        load_str cmp_var result_var cmp_var true_l false_l
  | {op= Const; ex= Mutation_op {dest; ex= Const_op value; _}} ->
      let value = gen_value value in
      gen_store_const_to_stack gen_fresh var_map dest value
  | _ -> failwith "unimp"

let gen_block_str gen_fresh (var_map : int String.Map.t)
    (block : labeled_block) =
  let instrs = List.map block.ops ~f:(gen_op_str gen_fresh var_map) in
  let instrs_str = String.concat instrs ~sep:"\n" in
  sprintf {|
%s:
%s
|} block.label instrs_str

let gen_function (funct : funct) =
  let name = funct.name in
  let vars = collect_variables funct.instrs in
  let var_idx_map =
    List.foldi vars ~init:String.Map.empty ~f:(fun idx map var ->
        Map.set map ~key:var ~data:idx )
  in
  let gen_fresh = create_fresh_var_gen vars in
  let stack_size = List.length vars in
  let blocks = basic_block_pass funct.instrs in
  let blocks = add_terminators blocks in
  let block_strs = List.map blocks ~f:(gen_block_str gen_fresh var_idx_map) in
  match blocks with
  | [] -> sprintf {|
define i64 @%s() {
  ret i64 0
}
|} funct.name
  | first_block :: _ ->
      (* Functions currently take no arguments*)
      sprintf
        {|
declare void @printi(i64)

define i64 @%s() {
  %%stack = alloca i64, i64 %d
  br label %%%s

  %s
}
|}
        name stack_size first_block.label
        (String.concat block_strs ~sep:"\n")
