open! Core

module Data_type : sig
  type i64

  type i1

  type 'a ptr
end

module Variable : sig
  type 'a t

  val create_fresh_var_gen : string list -> unit -> 'a t
end

module Stack : sig
  val create : int -> string * Data_type.i64 Data_type.ptr Variable.t
end

module Block : sig
  type t

  val create : string -> t

  val to_string : t -> string

  val append_gen_ptr :
       t
    -> gen_fresh:(unit -> 'a Variable.t)
    -> Data_type.i64 Data_type.ptr Variable.t
    -> int
    -> Data_type.i64 Data_type.ptr Variable.t

  val append_load :
       t
    -> gen_fresh:(unit -> 'a Variable.t)
    -> Data_type.i64 Data_type.ptr Variable.t
    -> Data_type.i64 Variable.t

  val append_store :
       t
    -> Data_type.i64 Data_type.ptr Variable.t
    -> Data_type.i64 Variable.t
    -> unit

  val append_const :
    t -> gen_fresh:(unit -> 'a Variable.t) -> int -> Data_type.i64 Variable.t

  val append_printi : t -> Data_type.i64 Variable.t -> unit

  val append_printb : t -> Data_type.i1 Variable.t -> unit

  val append_ret : t -> unit

  val append_jmp : t -> string -> unit

  val append_br : t -> string -> string -> Data_type.i1 Variable.t -> unit

  val append_ne :
       t
    -> gen_fresh:(unit -> 'a Variable.t)
    -> Data_type.i64 Variable.t
    -> Data_type.i64 Variable.t
    -> Data_type.i1 Variable.t

  val append_add :
       t
    -> gen_fresh:(unit -> 'a Variable.t)
    -> Data_type.i64 Variable.t
    -> Data_type.i64 Variable.t
    -> Data_type.i64 Variable.t
end
