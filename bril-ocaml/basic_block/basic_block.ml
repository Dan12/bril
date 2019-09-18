open! Core
open! Bril_lib.Bril

type maybe_labeled_block = {label: ident option; ops: operation list}
[@@deriving sexp]

let split_blocks instrs : maybe_labeled_block list =
  let process_next_instr (cur_blocks, cur_block) instr =
    match instr with
    | Label label -> (cur_block :: cur_blocks, {label= Some label; ops= []})
    | Operation op -> (
      match op with
      | Br _ | Jmp _ | Ret ->
          ( {cur_block with ops= op :: cur_block.ops} :: cur_blocks
          , {label= None; ops= []} )
      | _ -> (cur_blocks, {cur_block with ops= op :: cur_block.ops}) )
  in
  let blocks, last_block =
    List.fold instrs ~init:([], {label= None; ops= []}) ~f:process_next_instr
  in
  let all_blocks = last_block :: blocks |> List.rev in
  List.map all_blocks ~f:(fun block -> {block with ops= List.rev block.ops})

let prune_empty_blocks (blocks : maybe_labeled_block list) =
  List.filter blocks ~f:(fun block -> List.length block.ops <> 0)

let fresh_label_gen cur_labels =
  let i = ref 0 in
  let rec next_label () =
    let label = sprintf "_%d" !i in
    incr i ;
    if List.mem cur_labels label ~equal:String.equal then next_label ()
    else label
  in
  next_label

let collect_labels blocks =
  List.fold blocks ~init:[] ~f:(fun labels block ->
      match block.label with Some label -> label :: labels | None -> labels )

type labeled_block = {label: ident; ops: operation list} [@@deriving sexp]

let label_blocks blocks : labeled_block list =
  let labels = collect_labels blocks in
  let fresh_label = fresh_label_gen labels in
  List.map blocks ~f:(fun block ->
      let label =
        match block.label with Some label -> label | None -> fresh_label ()
      in
      {label; ops= block.ops} )

let create_next_block_map (blocks : labeled_block list) =
  List.fold blocks ~init:(String.Map.empty, None) ~f:(fun (map, prev) block ->
      match prev with
      | Some prev -> (Map.set map ~key:prev ~data:block.label, Some block.label)
      | None -> (map, Some block.label) )
  |> fst

let add_terminators (blocks : labeled_block list) =
  let next_block_map = create_next_block_map blocks in
  List.map blocks ~f:(fun block ->
      let rev_ops = List.rev block.ops in
      match rev_ops with
      | Br _ :: _ | Jmp _ :: _ | Ret :: _ -> block
      | _ ->
          let last_op =
            match Map.find next_block_map block.label with
            | Some next -> Jmp next
            | None -> Ret
          in
          {block with ops= last_op :: rev_ops |> List.rev} )

let basic_block_pass instrs =
  let blocks = split_blocks instrs in
  let blocks = prune_empty_blocks blocks in
  label_blocks blocks

type cfg_node = {ops: operation list; outgoing_edges: ident list}
[@@deriving sexp]

type cfg = cfg_node String.Map.t [@@deriving sexp]

let create_cfg (blocks : labeled_block list) =
  let next_block_map = create_next_block_map blocks in
  List.fold blocks ~init:String.Map.empty ~f:(fun cfg block ->
      let outgoing_edges =
        match List.rev block.ops with
        | Br {true_l; false_l; _} :: _ -> [true_l; false_l]
        | Jmp l :: _ -> [l]
        | Ret :: _ -> []
        | _ -> (
          match Map.find next_block_map block.label with
          | Some next -> [next]
          | None -> [] )
      in
      Map.set cfg ~key:block.label ~data:{ops= block.ops; outgoing_edges} )
