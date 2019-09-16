open! Core
open! Bril

type basic_block = {ops: Bril.operation list; outgoing_edges: ident}

type cfg = basic_block String.Map.t

let split_blocks instrs =
  let process_next_instr (cur_blocks, cur_block) instr =
    match instr with
    | Label _ -> (List.rev cur_block :: cur_blocks, [instr])
    | Operation op -> (
      match op with
      | Br _ | Jmp _ | Ret ->
          ((instr :: cur_block |> List.rev) :: cur_blocks, [])
      | _ -> (cur_blocks, instr :: cur_block) )
  in
  let blocks, last_block =
    List.fold instrs ~init:([], []) ~f:process_next_instr
  in
  List.rev last_block :: blocks |> List.rev

let prune_empty_blocks blocks =
  List.filter blocks ~f:(fun block -> List.length block <> 0)

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
      List.fold block ~init:labels ~f:(fun labels instr ->
          match instr with Label label -> label :: labels | _ -> labels ) )

let label_blocks blocks =
  let labels = collect_labels blocks in
  let fresh_label = fresh_label_gen labels in
  List.map blocks ~f:(fun block ->
      match block with
      | Label _ :: _ -> block
      | _ -> Label (fresh_label ()) :: block )
