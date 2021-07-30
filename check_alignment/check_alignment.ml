open! Core_kernel
open! Bio_io
open Lib

let version = match%const [%getenv "GIT_COMMIT_HASH"] with "" -> "na" | x -> x

let usage_msg = [%string "usage: %{Sys.argv.(0)} <infile> <col_1> [col_2 ...]"]
let help_msg = [%string "check_alignment version %{version}\n\n%{usage_msg}"]

let infile, positions =
  match Sys.argv |> Array.to_list with
  | [ _name; infile; pos ] -> (infile, [ Int.of_string pos ])
  | _name :: infile :: pos1 :: posns ->
      (infile, List.map (pos1 :: posns) ~f:Int.of_string)
  | _ ->
      prerr_endline help_msg;
      exit 1

let () = run infile positions
