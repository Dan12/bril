open! Core
open! Bril_lib.Bril

type labeled_block = {label: ident; ops: operation list} [@@deriving sexp]

(** [basic_block_pass] transforms a list of instructions into
    a list of labeled basic blocks, creating fresh labels as
    necessary for blocks.*)

val basic_block_pass : function_instruction list -> labeled_block list

val add_terminators : labeled_block list -> labeled_block list

type cfg_node = {ops: operation list; outgoing_edges: ident list}
[@@deriving sexp]

type cfg = cfg_node String.Map.t [@@deriving sexp]

(** [create_cfg blocks] each block in [blocks] is not required
    to end in terminator *)

val create_cfg : labeled_block list -> cfg
