open! Core_kernel

(* Types *)

exception Bad_stats_file_header of string [@@deriving sexp]

type coverage = {
  id : string;
  sample : string;
  avg_fold : float;
  length : int;
  num_reads : int;
}

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
let float_of_string s = try1 ~msg:"Error parsing int" Float.of_string s

let sort set = Hash_set.to_list set |> List.sort ~compare:String.compare

(* Program stuff *)

let count_weight = 1000.0

let expected_header =
  "#ID\tAvg_fold\tLength\tRef_GC\tCovered_percent\tCovered_bases\tPlus_reads\tMinus_reads\tRead_GC\tMedian_fold\tStd_Dev"

(* Sample names are expected to be in the filename. It needs to be able to be
   pulled out with a Regex, else an Error is return. *)
let get_sample_name ~pattern ~filename =
  let open Or_error.Let_syntax in
  let%bind re = Re2.create pattern in
  let%bind matches = Re2.find_all ~sub:(`Index 1) re filename in
  match List.length matches with
  | 1 -> Or_error.return @@ List.hd_exn matches
  | n -> Or_error.errorf "Found %d matches in %s" n filename

(* Process a line of the stats file into a coverage record. *)
let process_stats_line ~sample ~line =
  let open Or_error.Let_syntax in
  match String.split line ~on:'\t' with
  | [
   id;
   avg_fold;
   length;
   _ref_gc;
   _covered_percent;
   _covered_bases;
   plus_reads;
   minus_reads;
   _read_gc;
   _median_fold;
   _std_dev;
  ] ->
      let%bind avg_fold = float_of_string avg_fold in
      let%bind length = int_of_string length in
      let%bind plus_reads = int_of_string plus_reads in
      let%bind minus_reads = int_of_string minus_reads in
      let num_reads = plus_reads + minus_reads in
      Or_error.return { id; sample; avg_fold; length; num_reads }
  | _ -> Or_error.errorf "Bad stats line: '%s'" line

(* Process lines of the coverage file. If there is an error in any of them, the
   whole return result will be an Error. If it's Ok, then all elements will be
   Ok. *)
let get_coverages ~sample ~filename =
  let f () =
    In_channel.with_file filename ~f:(fun chan ->
        let _i, coverages =
          In_channel.fold_lines chan ~init:(0, []) ~f:(fun (i, acc) line ->
              if i = 0 then
                if String.(line <> expected_header) then
                  raise (Bad_stats_file_header line)
                else (i + 1, acc)
              else
                let coverage =
                  process_stats_line ~sample ~line |> Or_error.ok_exn
                in
                (i + 1, coverage :: acc))
        in
        coverages)
  in
  try0 ~msg:"Error processing stats file" f

(* For each record in the stats file, track the sample, contig name, and get the
   count of this contig in this sample. *)
let process_coverage ~all_samples ~all_contigs ~count_table coverage =
  let sample = coverage.sample in
  let contig = coverage.id in
  Hash_set.add all_samples sample;
  Hash_set.add all_contigs contig;
  let counts =
    Hashtbl.find_or_add count_table contig ~default:(fun () ->
        Hashtbl.create (module String))
  in
  if Hashtbl.mem counts sample then
    Or_error.error_string [%string "%{contig} is duplicated in %{sample}"]
  else
    let weighted_count =
      Float.(
        of_int coverage.num_reads /. of_int coverage.length *. count_weight)
    in
    Or_error.return @@ Hashtbl.set counts ~key:sample ~data:weighted_count

(* Process one of the stats files. Get the sample name, convert rows to
   coveragesand track the samples, contigs, and counts. *)
let process_stats_file ~all_samples ~all_contigs ~count_table ~pattern ~filename
    =
  let open Or_error.Let_syntax in
  let%bind sample = get_sample_name ~pattern ~filename in
  let%bind coverages = get_coverages ~sample ~filename in
  let f () =
    List.iter coverages ~f:(fun coverage ->
        process_coverage coverage ~all_samples ~all_contigs ~count_table
        |> ok_exn)
  in
  try0 ~msg:[%string "Error processing stats_file %{filename}"] f

let print_count_table ~sorted_samples ~sorted_contigs ~count_table =
  List.iter sorted_contigs ~f:(fun contig ->
      let counts = Hashtbl.find_exn count_table contig in
      let all_counts =
        List.map sorted_samples ~f:(fun sample ->
            let count =
              Hashtbl.find counts sample |> Option.value ~default:0.0
            in
            Float.to_string count)
        |> String.concat ~sep:"\t"
      in
      print_endline [%string "%{contig}\t%{all_counts}"])

let run pattern infiles =
  let all_samples = Hash_set.create (module String) in
  let all_contigs = Hash_set.create (module String) in
  (* contig -> sample -> coverage *)
  let count_table = Hashtbl.create (module String) in
  Array.iter infiles ~f:(fun filename ->
      process_stats_file ~all_samples ~all_contigs ~count_table ~pattern
        ~filename
      |> Or_error.ok_exn);
  let sorted_samples = sort all_samples in
  let sorted_contigs = sort all_contigs in
  let header =
    let samples = String.concat sorted_samples ~sep:"\t" in
    [%string "contig\t%{samples}"]
  in
  print_endline header;
  print_count_table ~sorted_samples ~sorted_contigs ~count_table
