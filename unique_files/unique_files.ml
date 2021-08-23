open! Core_kernel

let filenames =
  match Array.to_list @@ Sys.argv with
  | [ _ ] | [] ->
      prerr_endline "usage: unique_files file1 ...";
      exit 1
  | _ :: names -> names

let uniques =
  List.fold filenames
    ~init:(Map.empty (module Md5))
    ~f:(fun digests filename ->
      let digest = Md5.digest_file_blocking filename in
      Map.update digests digest ~f:(function
        | Some names -> filename :: names
        | None -> [ filename ]))

let () =
  Map.iteri uniques ~f:(fun ~key:digest ~data:filenames ->
      let digest = Md5.to_hex digest in
      let names =
        List.dedup_and_sort filenames ~compare:String.compare
        |> String.concat ~sep:"\t"
      in
      print_endline [%string "%{digest}\t%{names}"])
