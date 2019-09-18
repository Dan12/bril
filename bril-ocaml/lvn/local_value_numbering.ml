open! Core
open! Bril_lib.Bril

type id = int [@@deriving compare]

type expression = Add of id * id | Mul of id * id | Empty
[@@deriving compare]

type var_name = ident

type table_row = {expr: expr; var_name: var_name}

type table = table_row Int.Map.t

type var_pointers = int String.Map.t

type value_number_struct = {table: table; var_pointers: var_pointers}

let fresh_id_get =
  let i = ref 0 in
  fun () ->
    let next_i = !i in
    incr i ; next_i

let fresh_var_gen cur_vars =
  let i = ref 0 in
  let rec next_var () =
    let label = sprintf "_v%d" !i in
    incr i ;
    if List.mem cur_vars label ~equal:String.equal then next_var () else label
  in
  next_var

(* rewrite args of exprs using the table *)
let process_block (instrs : operation list) =
  let add_const dest table pointers =
    let table_idx = fresh_id_get () in
    let new_table =
      Map.set table ~key:table_idx ~data:{expr= Empty; var_name= dest}
    in
    let new_pointers = Map.set pointers ~key:dest ~data:table_idx in
    (new_table, new_pointers)
  in
  List.fold instrs ~init:(Int.Map.empty, String.Map.empty)
    ~f:(fun (table, pointers) instr ->
      match instr with
      | Const {dest; _} -> add_const dest table pointers
      | _ -> failwith "unimplemented" )
