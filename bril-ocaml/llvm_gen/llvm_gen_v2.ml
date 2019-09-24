open! Core
open! Bril_lib.Bril_v2
open! Basic_block_lib.Basic_block_v2
open! Llvm

module type G = sig
  val gen_fresh : 'a Data_type.t -> 'a Variable.t
end

let typ_to_data_type (t : typ) : Data_type.packed =
  match t with
  | Int -> Data_type.pack Data_type.Int
  | Bool -> Data_type.pack Data_type.Bool

let collect_variables (instrs : function_instruction list) :
    ident list * Data_type.packed list =
  List.fold instrs ~init:([], []) ~f:(fun (vars, typs) instr ->
      match instr with
      | Label _ -> (vars, typs)
      | Operation op -> (
        match op with
        | Any {ex= Mutation_op {dest; typ; _}; _}
          when not (List.mem vars dest ~equal:String.equal) ->
            (dest :: vars, typ_to_data_type typ :: typs)
        | Any {ex= Id_op {dest; typ; _}; _}
          when not (List.mem vars dest ~equal:String.equal) ->
            (dest :: vars, typ_to_data_type typ :: typs)
        | _ -> (vars, typs) ) )

let gen_load_from_stack ~stack ~block ~gen_fresh_mod ~var_map to_load =
  let module Gen_Fresh = (val gen_fresh_mod : G) in
  let gen_fresh = Gen_Fresh.gen_fresh in
  match Map.find var_map to_load with
  | None -> Block.append_const block ~gen_fresh ~value:0
  | Some load_idx ->
      let ptr =
        Block.append_gen_struct_ptr block ~gen_fresh ~base:stack
          ~offset:load_idx
      in
      Block.append_load block ~gen_fresh ~ptr

let gen_store_to_stack ~stack ~block ~gen_fresh ~var_map to_store arg =
  match Map.find var_map to_store with
  | None -> ()
  | Some store_idx ->
      let ptr =
        Block.append_gen_struct_ptr block ~gen_fresh ~base:stack
          ~offset:store_idx
      in
      Block.append_store block ~ptr ~arg

let process_op ~stack ~block ~gen_fresh_mod ~var_map op =
  let module Gen_Fresh = (val gen_fresh_mod : G) in
  let gen_fresh = Gen_Fresh.gen_fresh in
  let (Any op) = op in
  match op with
  | {ex= Effect_op {args; _}; _} -> (
    match args with
    | Jmp label -> Block.append_jmp block ~label
    | Ret -> Block.append_ret block
    | Print args ->
        List.iter args ~f:(fun arg ->
            let arg =
              gen_load_from_stack ~stack ~block ~gen_fresh_mod ~var_map arg
            in
            Block.append_printi block ~arg )
    | Br {var; true_l; false_l} ->
        let arg =
          gen_load_from_stack ~block ~stack ~gen_fresh_mod ~var_map var
        in
        let zero = Block.append_const block ~gen_fresh ~value:0 in
        let cmp_result =
          Block.append_ne block ~gen_fresh ~arg1:arg ~arg2:zero
        in
        Block.append_br block ~true_l ~false_l ~arg:cmp_result )
  | _ -> failwith "uimp"

let gen_block_str ~stack ~gen_fresh_mod ~var_map (basic_block : labeled_block)
    =
  let block = Block.create basic_block.label in
  List.iter basic_block.ops
    ~f:(process_op ~stack ~block ~gen_fresh_mod ~var_map) ;
  Block.to_string block

let gen_function (funct : funct) =
  let name = funct.name in
  let vars, typs = collect_variables funct.instrs in
  let var_idx_map =
    List.foldi vars ~init:String.Map.empty ~f:(fun idx map var ->
        Map.set map ~key:var ~data:idx )
  in
  let module Gen_Fresh : G = Gen_Fresh (struct
    let vars = vars
  end) in
  let gen_fresh_mod = (module Gen_Fresh : G) in
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
      let stack = Stack.create ~var_typ_list:typs in
      let block_strs =
        List.map blocks
          ~f:(gen_block_str ~stack ~gen_fresh_mod ~var_map:var_idx_map)
      in
      sprintf {|
define i64 @%s() {
  %s
  br label %%%s

  %s
}
|} name
        (Stack.gen_init_str stack) first_block.label
        (String.concat block_strs ~sep:"\n")
