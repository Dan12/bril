open! Core
open! Yojson.Basic

module Reader = struct
  let from_file filename =
    let json_tree = from_file filename in
    let program = Parse.parse_program json_tree in
    let program = Or_error.bind program ~f:Transform.transform_program in
    program
end

module Writer = struct
  let to_file program filename =
    let json = Bril_writer.gen_program program in
    let out_channel = Out_channel.create filename in
    pretty_to_channel out_channel json
end

module Transform_v2 = Transform_v2
