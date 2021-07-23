open! Core_kernel

(* Utils *)

let abort ?(exit_code = 1) msg =
  let () = eprintf "%s\n" msg in
  exit exit_code

let try0 ~msg f =
  match f () with
  | exception exn -> Or_error.error msg exn Exn.sexp_of_t
  | result -> Or_error.return result

let try1 ~msg f a =
  match f a with
  | exception exn -> Or_error.error msg exn Exn.sexp_of_t
  | result -> Or_error.return result

let int_of_string s = try1 ~msg:"Error parsing int" Int.of_string s
let float_of_string s = try1 ~msg:"Error parsing float" Float.of_string s

let sort_string_set set =
  Hash_set.to_list set |> List.sort ~compare:String.compare
