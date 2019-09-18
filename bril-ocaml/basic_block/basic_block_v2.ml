open! Core
open! Bril_lib.Bril_v2

type maybe_labeled_block = {label: ident option; ops: any_op list}

let split_blocks instrs : maybe_labeled_block list =
  let process_next_instr (cur_blocks, cur_block) instr =
    match instr with
    | Label label -> (cur_block :: cur_blocks, {label= Some label; ops= []})
    | Operation op -> (
        let end_block () =
          ( {cur_block with ops= op :: cur_block.ops} :: cur_blocks
          , {label= None; ops= []} )
        in
        let (Any operation) = op in
        match operation.op with
        | Br -> end_block ()
        | Jmp -> end_block ()
        | Ret -> end_block ()
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

type labeled_block = {label: ident; ops: any_op list}

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
      | Any {op= Br; _} :: _ -> block
      | Any {op= Jmp; _} :: _ -> block
      | Any {op= Ret; _} :: _ -> block
      | _ ->
          let last_op =
            match Map.find next_block_map block.label with
            | Some next ->
                Any {op= Jmp; ex= Effect_op {op= Jmp; args= Jmp next}}
            | None -> Any {op= Ret; ex= Effect_op {op= Ret; args= Ret}}
          in
          {block with ops= last_op :: rev_ops |> List.rev} )

let basic_block_pass instrs =
  let blocks = split_blocks instrs in
  let blocks = prune_empty_blocks blocks in
  label_blocks blocks

type cfg_node = {ops: any_op list; outgoing_edges: ident list}

type cfg = cfg_node String.Map.t

let create_cfg (blocks : labeled_block list) =
  let next_block_map = create_next_block_map blocks in
  List.fold blocks ~init:String.Map.empty ~f:(fun cfg block ->
      let outgoing_edges =
        match List.rev block.ops with
        | Any {op= Br; ex= Effect_op {args= Br {true_l; false_l; _}; _}} :: _
          ->
            [true_l; false_l]
        | Any {op= Jmp; ex= Effect_op {args= Jmp l; _}} :: _ -> [l]
        | Any {op= Ret; _} :: _ -> []
        | _ -> (
          match Map.find next_block_map block.label with
          | Some next -> [next]
          | None -> [] )
      in
      Map.set cfg ~key:block.label ~data:{ops= block.ops; outgoing_edges} )
