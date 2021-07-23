open! Core_kernel
open! Hfsp

let print_line_parse_result x =
  print_endline
  @@ Sexp.to_string_hum ~indent:1 ([%sexp_of: Lib.search_record Or_error.t] x)

let%expect_test _ =
  print_line_parse_result @@ Lib.parse_search_line "a\tb\t1\t2\t1M2D3I";
  [%expect
    {|
    (Ok
     ((query a) (target b) (pident 100) (bit_score 2)
      (cigar
       (((count 1) (op Match)) ((count 2) (op Deletion))
        ((count 3) (op Insertion)))))) |}]

let%expect_test "fractions get turned to percents" =
  print_line_parse_result @@ Lib.parse_search_line "a\tb\t0.5\t2\t1M2D3I";
  [%expect
    {|
    (Ok
     ((query a) (target b) (pident 50) (bit_score 2)
      (cigar
       (((count 1) (op Match)) ((count 2) (op Deletion))
        ((count 3) (op Insertion)))))) |}]

let%expect_test _ =
  print_line_parse_result @@ Lib.parse_search_line "a b 1 2 1M2D3I";
  [%expect
    {| (Error "Wrong number of tokens when parsing line: 'a b 1 2 1M2D3I'") |}]

let%expect_test _ =
  print_line_parse_result @@ Lib.parse_search_line "";
  [%expect {| (Error "Wrong number of tokens when parsing line: ''") |}]

let%expect_test _ =
  print_line_parse_result @@ Lib.parse_search_line "a\tb\tc\td\te";
  [%expect
    {| (Error ("Error parsing float" (Invalid_argument "Float.of_string c"))) |}]

let%expect_test _ =
  print_line_parse_result @@ Lib.parse_search_line "a\tb\t1\td\te";
  [%expect
    {| (Error ("Error parsing float" (Invalid_argument "Float.of_string d"))) |}]

let%expect_test _ =
  print_line_parse_result @@ Lib.parse_search_line "a\tb\t1\t2\tpie";
  [%expect
    {|
    (Error
     ("Error parsing cigar string"
      (lib/cigar.ml.Cigar_parse_exn "Expected int or Operation. Got p"))) |}]

let%expect_test "fident too low" =
  print_line_parse_result @@ Lib.parse_search_line "a\tb\t-0.5\t2\tM";
  [%expect {| (Error "fident should be between 0 and 1.  Got -0.500000.") |}]

let%expect_test "fident too high" =
  print_line_parse_result @@ Lib.parse_search_line "a\tb\t1.5\t2\tM";
  [%expect {| (Error "fident should be between 0 and 1.  Got 1.500000.") |}]
