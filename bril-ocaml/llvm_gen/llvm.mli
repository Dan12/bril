open! Core

module Data_type : sig
  type i64

  type i1

  type 'a ptr = P of 'a

  type strct

  type _ t =
    | Int : i64 t
    | Bool : i1 t
    | Ptr : 'a t -> 'a ptr t
    | Strct : packed list -> strct t

  and packed

  val pack : _ t -> packed

  val to_string : _ t -> string
end

module Variable : sig
  type 'a t

  val create_fresh_var_gen : string list -> 'a Data_type.t -> 'a t
end

module Gen_Fresh (Vars : sig
  val vars : string list
end) : sig
  val gen_fresh : 'a Data_type.t -> 'a Variable.t
end

module Stack : sig
  val create : var_typ_list:Data_type.packed list -> Data_type.strct Variable.t

  val gen_init_str : Data_type.strct Variable.t -> string
end

module Block : sig
  type t

  val create : string -> t

  val to_string : t -> string

  val append_gen_ptr :
       t
    -> gen_fresh:(   Data_type.i64 Data_type.ptr Data_type.t
                  -> Data_type.i64 Data_type.ptr Variable.t)
    -> base:Data_type.i64 Data_type.ptr Variable.t
    -> offset:int
    -> Data_type.i64 Data_type.ptr Variable.t

  val append_gen_struct_ptr :
       t
    -> gen_fresh:(   Data_type.i64 Data_type.ptr Data_type.t
                  -> Data_type.i64 Data_type.ptr Variable.t)
    -> base:Data_type.strct Variable.t
    -> offset:int
    -> Data_type.i64 Data_type.ptr Variable.t

  val append_load :
       t
    -> gen_fresh:(Data_type.i64 Data_type.t -> Data_type.i64 Variable.t)
    -> ptr:Data_type.i64 Data_type.ptr Variable.t
    -> Data_type.i64 Variable.t

  val append_store :
       t
    -> ptr:Data_type.i64 Data_type.ptr Variable.t
    -> arg:Data_type.i64 Variable.t
    -> unit

  val append_const :
       t
    -> gen_fresh:(Data_type.i64 Data_type.t -> Data_type.i64 Variable.t)
    -> value:int
    -> Data_type.i64 Variable.t

  val append_printi : t -> arg:Data_type.i64 Variable.t -> unit

  val append_printb : t -> arg:Data_type.i1 Variable.t -> unit

  val append_ret : t -> unit

  val append_jmp : t -> label:string -> unit

  val append_br :
    t -> true_l:string -> false_l:string -> arg:Data_type.i1 Variable.t -> unit

  val append_ne :
       t
    -> gen_fresh:(Data_type.i1 Data_type.t -> Data_type.i1 Variable.t)
    -> arg1:Data_type.i64 Variable.t
    -> arg2:Data_type.i64 Variable.t
    -> Data_type.i1 Variable.t

  val append_add :
       t
    -> gen_fresh:(Data_type.i64 Data_type.t -> Data_type.i64 Variable.t)
    -> arg1:Data_type.i64 Variable.t
    -> arg2:Data_type.i64 Variable.t
    -> Data_type.i64 Variable.t
end
