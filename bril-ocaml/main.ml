open! Core
open! Yojson.Basic

let main json_file () =
  let json_tree = from_file json_file in
  let program = Parse.parse_program json_tree in
  let program = Or_error.bind program ~f:Transform.transform_program in
  let blocks =
    Or_error.map program ~f:(fun program ->
        let blocks =
          Basic_block.split_blocks (List.nth_exn program.functions 0).instrs
        in
        let blocks = Basic_block.prune_empty_blocks blocks in
        Basic_block.label_blocks blocks )
  in
  printf !"%{sexp: Bril.program Or_error.t}\n\n" program ;
  printf !"%{sexp: Bril.function_instruction list list Or_error.t}\n" blocks

let () =
  let open Command.Let_syntax in
  Command.basic ~summary:"Bril parser"
    [%map_open
      let json_file = anon ("bril json file" %: file) in
      main json_file]
  |> Command.run
