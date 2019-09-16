open! Core
open! Yojson.Basic

let main json_file () =
  let json_tree = from_file json_file in
  let program = Parse.parse_program json_tree in
  let program = Or_error.bind program ~f:Transform.transform_program in
  printf !"%{sexp: Bril.program Or_error.t}" program

let () =
  let open Command.Let_syntax in
  Command.basic ~summary:"Bril parser"
    [%map_open
      let json_file = anon ("bril json file" %: file) in
      main json_file]
  |> Command.run
