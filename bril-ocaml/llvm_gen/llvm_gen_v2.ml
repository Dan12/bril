open! Core
open! Bril_lib.Bril_v2
open! Basic_block_lib.Basic_block_v2
open! Llvm

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

let gen_load_from_stack stack block gen_fresh var_idx to_load =
  match Map.find var_idx to_load with
  | None -> Block.append_const block ~gen_fresh 0
  | Some load_idx ->
      let ptr = Block.append_gen_ptr block ~gen_fresh stack load_idx in
      Block.append_load block ~gen_fresh ptr

let gen_store_to_stack stack block gen_fresh var_idx to_store arg =
  match Map.find var_idx to_store with
  | None -> ()
  | Some store_idx ->
      let ptr = Block.append_gen_ptr block ~gen_fresh stack store_idx in
      Block.append_store block ptr arg

let process_op stack block gen_fresh var_idx op =
  let (Any op) = op in
  match op with
  | {ex= Effect_op {args; _}; _} -> (
    match args with
    | Jmp label -> Block.append_jmp block label
    | Ret -> Block.append_ret block
    | Print args ->
        List.iter args ~f:(fun arg ->
            let arg = gen_load_from_stack stack block gen_fresh var_idx arg in
            Block.append_printi block arg )
    | Br {var; true_l; false_l} ->
        let arg = gen_load_from_stack stack block gen_fresh var_idx var in
        let zero = Block.append_const block ~gen_fresh 0 in
        let cmp_result = Block.append_ne block ~gen_fresh arg zero in
        Block.append_br block true_l false_l cmp_result )
  | _ -> failwith "uimp"

let gen_block_str stack gen_fresh var_idx (basic_block : labeled_block) =
  let block = Block.create basic_block.label in
  List.iter basic_block.ops ~f:(process_op stack block gen_fresh var_idx) ;
  Block.to_string block

let gen_function (funct : funct) =
  let name = funct.name in
  let vars = collect_variables funct.instrs in
  let var_idx_map =
    List.foldi vars ~init:String.Map.empty ~f:(fun idx map var ->
        Map.set map ~key:var ~data:idx )
  in
  let gen_fresh = Variable.create_fresh_var_gen vars in
  let stack_size = List.length vars in
  let blocks = basic_block_pass funct.instrs in
  let blocks = add_terminators blocks in
  match blocks with
  | [] -> sprintf {|
define i64 @%s() {
  ret i64 0
}
|} funct.name
  | first_block :: _ ->
      (* Functions currently take no arguments*)
      let stack_str, stack = Stack.create stack_size in
      let block_strs =
        List.map blocks ~f:(gen_block_str stack gen_fresh var_idx_map)
      in
      sprintf {|
define i64 @%s() {
  %s
  br label %%%s

  %s
}
|} name
        stack_str first_block.label
        (String.concat block_strs ~sep:"\n")
