open! Core
open! Bril_lib

val transform_program : Parse.program -> Bril.program Or_error.t
