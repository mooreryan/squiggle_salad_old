open! Core_kernel
open Hfsp.Cigar

(* let redact s =
 *   Re2.replace_exn (Re2.create_exn "\\(.*Cigar") s ~f:(fun _ ->
 *       "(REDACTED Cigar")
 * in
 * let print_it x =
 *   print_endline @@ redact
 *   @@ Sexp.to_string_hum ~indent:1 ([%sexp_of: Lib.search_record Or_error.t] x)
 * in *)

let print_cigar_parse_result x =
  let redact s =
    Re2.replace_exn (Re2.create_exn "\\(.*Cigar") s ~f:(fun _ ->
        "(REDACTED Cigar")
  in
  print_endline @@ redact
  @@ Sexp.to_string_hum ~indent:1 ([%sexp_of: cigar_pair list Or_error.t] x)

let%expect_test _ =
  print_cigar_parse_result @@ parse_cigar_string "Apple";
  [%expect
    {|
    (Error
     ("Error parsing cigar string"
      (REDACTED Cigar_parse_exn "Expected int or Operation. Got A"))) |}]

let%expect_test _ =
  print_cigar_parse_result @@ parse_cigar_string "123Aapple";
  [%expect
    {|
    (Error
     ("Error parsing cigar string"
      (REDACTED Cigar_parse_exn "Expected int or Operation. Got A"))) |}]

let%expect_test _ =
  print_cigar_parse_result @@ parse_cigar_string "M";
  [%expect {| (Ok (((count 1) (op Match)))) |}]

let%expect_test _ =
  print_cigar_parse_result @@ parse_cigar_string "D";
  [%expect {| (Ok (((count 1) (op Deletion)))) |}]

let%expect_test _ =
  print_cigar_parse_result @@ parse_cigar_string "I";
  [%expect {| (Ok (((count 1) (op Insertion)))) |}]

let%expect_test _ =
  print_cigar_parse_result @@ parse_cigar_string "1M";
  [%expect {| (Ok (((count 1) (op Match)))) |}]

let%expect_test _ =
  print_cigar_parse_result @@ parse_cigar_string "1D";
  [%expect {| (Ok (((count 1) (op Deletion)))) |}]

let%expect_test _ =
  print_cigar_parse_result @@ parse_cigar_string "1I";
  [%expect {| (Ok (((count 1) (op Insertion)))) |}]

let%expect_test _ =
  print_cigar_parse_result @@ parse_cigar_string "2M";
  [%expect {| (Ok (((count 2) (op Match)))) |}]

let%expect_test _ =
  print_cigar_parse_result @@ parse_cigar_string "2D";
  [%expect {| (Ok (((count 2) (op Deletion)))) |}]

let%expect_test _ =
  print_cigar_parse_result @@ parse_cigar_string "2I";
  [%expect {| (Ok (((count 2) (op Insertion)))) |}]

let%expect_test _ =
  print_cigar_parse_result @@ parse_cigar_string "1M2D3I4M5D6I";
  [%expect
    {|
    (Ok
     (((count 1) (op Match)) ((count 2) (op Deletion)) ((count 3) (op Insertion))
      ((count 4) (op Match)) ((count 5) (op Deletion))
      ((count 6) (op Insertion)))) |}]

let%expect_test "for now, same op back to back is okay" =
  print_cigar_parse_result @@ parse_cigar_string "2M3M";
  [%expect {| (Ok (((count 2) (op Match)) ((count 3) (op Match)))) |}]

let%expect_test "no integers mean 1" =
  print_cigar_parse_result @@ parse_cigar_string "M1MDI";
  [%expect
    {|
    (Ok
     (((count 1) (op Match)) ((count 1) (op Match)) ((count 1) (op Deletion))
      ((count 1) (op Insertion)))) |}]

(* Ungapped length *)

let%test _ =
  let cigar = parse_cigar_string "10MM" |> Or_error.ok_exn in
  ungapped_length cigar = 11

let%test _ =
  let cigar = parse_cigar_string "1M1D1I1M" |> Or_error.ok_exn in
  ungapped_length cigar = 2

let%test _ =
  let cigar = parse_cigar_string "DIDIDIDIDIDIDDDI" |> Or_error.ok_exn in
  ungapped_length cigar = 0
