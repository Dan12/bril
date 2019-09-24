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

let collect_variables_and_types (instrs : function_instruction list) :
    ident list * typ list =
  List.fold instrs ~init:([], []) ~f:(fun (vars, typs) instr ->
      match instr with
      | Label _ -> (vars, typs)
      | Operation op -> (
        match op with
        | Any {ex= Mutation_op {dest; typ; _}; _}
          when not (List.mem vars dest ~equal:String.equal) ->
            (dest :: vars, typ :: typs)
        | Any {ex= Id_op {dest; typ; _}; _}
          when not (List.mem vars dest ~equal:String.equal) ->
            (dest :: vars, typ :: typs)
        | _ -> (vars, typs) ) )

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

let gen_load_from_stack ~gen_fresh ~var_map to_load =
  let ptr_var = gen_fresh () in
  let result_var = gen_fresh () in
  match Map.find var_map to_load with
  | None -> ("", result_var)
  | Some load_idx ->
      ( sprintf
          {|
  %%%s = getelementptr inbounds i64, i64* %%stack, i64 %d
  %%%s = load i64, i64* %%%s
|}
          ptr_var load_idx result_var ptr_var
      , result_var )

let gen_store_const_to_stack ~gen_fresh ~var_map ~dest const =
  let ptr_var = gen_fresh () in
  match Map.find var_map dest with
  | None -> ""
  | Some dest_idx ->
      sprintf
        {|
 %%%s = getelementptr inbounds i64, i64* %%stack, i64 %d
 store i64 %d, i64* %%%s
|}
        ptr_var dest_idx const ptr_var

let gen_store_var_to_stack ~gen_fresh ~var_map ~dest to_store =
  let ptr_var = gen_fresh () in
  match Map.find var_map dest with
  | None -> ""
  | Some dest_idx ->
      sprintf
        {|
 %%%s = getelementptr inbounds i64, i64* %%stack, i64 %d
 store i64 %%%s, i64* %%%s
|}
        ptr_var dest_idx to_store ptr_var

let gen_value (value : value) =
  match value with Int i -> i | Bool b -> if b then 1 else 0

let gen_op_str gen_fresh (var_map : int String.Map.t) (typ_map : typ Int.Map.t)
    (op : any_op) =
  let (Any op) = op in
  match op with
  | {ex= Effect_op {args; _}; _} -> (
    match args with
    | Jmp label -> sprintf "br label %%%s" label
    | Ret -> sprintf "ret i64 0"
    | Print args ->
        let arg_prints =
          List.map args ~f:(fun arg ->
              let load_str, result_var =
                gen_load_from_stack ~gen_fresh ~var_map arg
              in
              match Map.find var_map arg with
              | None -> ""
              | Some idx -> (
                match Map.find typ_map idx with
                | None -> ""
                | Some typ -> (
                  match typ with
                  | Int ->
                      sprintf {|
  %s
  call void @printi(i64 %%%s)
|} load_str
                        result_var
                  | Bool ->
                      sprintf {|

  %s
  call void @printb(i64 %%%s)
|}
                        load_str result_var ) ) )
        in
        sprintf "%s" (String.concat arg_prints ~sep:"\n")
    | Br {var; true_l; false_l} ->
        let load_str, result_var =
          gen_load_from_stack ~gen_fresh ~var_map var
        in
        let cmp_var = gen_fresh () in
        sprintf
          {|
  %s
  %%%s = icmp ne i64 %%%s, 0
  br i1 %%%s, label %%%s, label %%%s
|}
          load_str cmp_var result_var cmp_var true_l false_l )
  | {op= Const; ex= Mutation_op {dest; ex= Const_op value; _}} ->
      let value = gen_value value in
      gen_store_const_to_stack ~gen_fresh ~var_map ~dest value
  | {ex= Mutation_op {dest; ex= Value_op {args= Un_op arg; _}; op= Not; _}; _}
    ->
      let load_str, load_result =
        gen_load_from_stack ~gen_fresh ~var_map arg
      in
      let result_var = gen_fresh () in
      let store_str =
        gen_store_var_to_stack ~gen_fresh ~var_map ~dest result_var
      in
      sprintf {|
  %s
  %%%s = sub i64 1, %%%s
  %s
|} load_str result_var
        load_result store_str
  | { ex=
        Mutation_op
          {dest; ex= Value_op {args= Bin_op {arg_l; arg_r; op; ex}; _}; _}; _
    } ->
      let load_left_str, left_result =
        gen_load_from_stack ~gen_fresh ~var_map arg_l
      in
      let load_right_str, right_result =
        gen_load_from_stack ~gen_fresh ~var_map arg_r
      in
      let result_var = gen_fresh () in
      let store_str =
        gen_store_var_to_stack ~gen_fresh ~var_map ~dest result_var
      in
      let binop_str =
        match ex with
        | Int_op ->
            let op_str =
              match op with
              | Add -> "add"
              | Sub -> "sub"
              | Mul -> "mul"
              | Div -> "sdiv"
            in
            sprintf "%%%s = %s i64 %%%s, %%%s" result_var op_str left_result
              right_result
        | Bool_op ->
            let op_str = match op with And -> "and" | Or -> "or" in
            sprintf "%%%s = %s i64 %%%s, %%%s" result_var op_str left_result
              right_result
        | Int_to_bool_op ->
            let op_str =
              match op with
              | Eq -> "eq"
              | Lt -> "slt"
              | Gt -> "sgt"
              | Le -> "sle"
              | Ge -> "sge"
            in
            let cmp_result = gen_fresh () in
            sprintf
              {|
  %%%s = icmp %s i64 %%%s, %%%s
  %%%s = zext i1 %%%s to i64
|}
              cmp_result op_str left_result right_result result_var cmp_result
      in
      sprintf {|
  %s
  %s
  %s
  %s
|} load_left_str load_right_str binop_str
        store_str
  | {ex= Nop_op; _} -> ""
  | {ex= Id_op {dest; arg; _}; _} ->
      let load_str, load_result =
        gen_load_from_stack ~gen_fresh ~var_map arg
      in
      let store_str =
        gen_store_var_to_stack ~gen_fresh ~var_map ~dest load_result
      in
      sprintf {|
%s
%s
|} load_str store_str

let gen_block_str gen_fresh (var_map : int String.Map.t)
    (typ_map : typ Int.Map.t) (block : labeled_block) =
  let instrs = List.map block.ops ~f:(gen_op_str gen_fresh var_map typ_map) in
  let instrs_str = String.concat instrs ~sep:"\n" in
  sprintf {|
%s:
  %s
|} block.label instrs_str

let gen_function (funct : funct) =
  let name = funct.name in
  let vars, typs = collect_variables_and_types funct.instrs in
  let var_idx_map =
    List.foldi vars ~init:String.Map.empty ~f:(fun idx map var ->
        Map.set map ~key:var ~data:idx )
  in
  let idx_typ_map =
    List.foldi typs ~init:Int.Map.empty ~f:(fun idx map typ ->
        Map.set map ~key:idx ~data:typ )
  in
  let gen_fresh = create_fresh_var_gen vars in
  let stack_size = List.length vars in
  let blocks = basic_block_pass funct.instrs in
  let blocks = add_terminators blocks in
  let block_strs =
    List.map blocks ~f:(gen_block_str gen_fresh var_idx_map idx_typ_map)
  in
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
define i64 @%s() {
  %%stack = alloca i64, i64 %d
  br label %%%s

  %s
}
|}
        name stack_size first_block.label
        (String.concat block_strs ~sep:"\n")
