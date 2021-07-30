open! Core_kernel
open! Lib

let print_sexp s = print_endline @@ Sexp.to_string_hum ~indent:1 s

let map_to_sexp m = [%sexp_of: (int * int) list] (Map.to_alist m)

(* make_position_map *)

let%expect_test _ =
  let aligned_seq = "-A-C-T-G-" in
  let position_map = make_position_map aligned_seq in
  print_sexp @@ map_to_sexp position_map;
  [%expect {| ((0 1) (1 3) (2 5) (3 7)) |}]

let%expect_test _ =
  let aligned_seq = "------" in
  let position_map = make_position_map aligned_seq in
  print_sexp @@ map_to_sexp position_map;
  [%expect {| () |}]

let%expect_test _ =
  let aligned_seq = "ACTG" in
  let position_map = make_position_map aligned_seq in
  print_sexp @@ map_to_sexp position_map;
  [%expect {| ((0 0) (1 1) (2 2) (3 3)) |}]
