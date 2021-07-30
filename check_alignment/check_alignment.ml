open! Core_kernel
open! Bio_io
open Lib

let infile, positions =
  match Sys.argv |> Array.to_list with
  | [ _name; infile; pos ] -> (infile, [ Int.of_string pos ])
  | _name :: infile :: pos1 :: posns ->
      (infile, List.map (pos1 :: posns) ~f:Int.of_string)
  | _ ->
      prerr_endline
        [%string "usage: %{Sys.argv.(0)} <infile> <col_1> [col_2 ...]"];
      exit 1

let () = run infile positions
