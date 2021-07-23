open! Core_kernel

(* Types *)

exception Exn of string [@@deriving sexp]

type search_record = {
  query : string;
  target : string;
  pident : float;
  bit_score : float;
  cigar : Cigar.cigar;
}
[@@deriving sexp]

type pair_score = {
  query : string;
  target : string;
  hfsp_score : float;
  bit_score : float;
}

let pair_score_to_string ps =
  [%string "%{ps.query}\t%{ps.target}\t%{ps.hfsp_score#Float}"]

let pair_score_key ps = [%string "%{ps.query}\t%{ps.target}"]

(* File parsing *)

(* See equation 4:
   https://academic.oup.com/bioinformatics/article/34/13/i304/5045799#E6 *)
let hfsp_score pident ungapped_len =
  let open Float in
  let f len = 770. * (len ** (-0.33 * (1. + exp (-len / 1000.)))) in
  let len = of_int ungapped_len in
  let subtrahend =
    if len <= 11. then 100.
    else if 11. < len && len <= 450. then f len
    else 28.4
  in
  pident - subtrahend

let parse_search_line line =
  let open Or_error.Let_syntax in
  match String.split line ~on:'\t' with
  | [ query; target; fident; bit_score; cigar ] ->
      let%bind fident = Utils.float_of_string fident in
      let pident = fident *. 100.0 in
      let%bind bit_score = Utils.float_of_string bit_score in
      let%bind cigar = Cigar.parse_cigar_string cigar in
      if Float.(fident < 0.0 || fident > 1.0) then
        Or_error.errorf "fident should be between 0 and 1.  Got %f." fident
      else Or_error.return { query; target; pident; bit_score; cigar }
  | _ -> Or_error.errorf "Wrong number of tokens when parsing line: '%s'" line

let parse_search_file fname =
  let open Or_error.Let_syntax in
  In_channel.read_lines fname
  |> List.mapi ~f:(fun i line ->
         let line_number = i + 1 in
         let%map search =
           parse_search_line line
           |> Or_error.tag ~tag:[%string "Error in line %{line_number#Int}"]
         in
         let score =
           hfsp_score search.pident (Cigar.ungapped_length search.cigar)
         in
         {
           query = search.query;
           target = search.target;
           hfsp_score = score;
           bit_score = search.bit_score;
         })

let get_overall_top_scores scores =
  List.fold scores
    ~init:(Map.empty (module String))
    ~f:(fun top_scores pair_score ->
      match pair_score with
      | Ok ps ->
          Map.update top_scores ps.query ~f:(fun score_pair ->
              match score_pair with
              | Some (old_target, old_score) ->
                  if Float.(ps.hfsp_score > old_score) then
                    (ps.target, ps.hfsp_score)
                  else (old_target, old_score)
              | None -> (ps.target, ps.hfsp_score))
      | Error err ->
          prerr_endline @@ Error.to_string_hum err;
          top_scores)

let print_overall_top_scores scores =
  Map.iteri scores ~f:(fun ~key:query ~data:(target, score) ->
      print_endline [%string "%{query}\t%{target}\t%{score#Float}"])

let get_pair_top_scores scores =
  let update_scores ps scores =
    match scores with
    | Some scores' ->
        Map.update scores' ps.target ~f:(fun old_score ->
            match old_score with
            | Some old_score' ->
                if Float.(ps.hfsp_score > old_score') then ps.hfsp_score
                else old_score'
            | None -> ps.hfsp_score)
    | None -> Map.of_alist_exn (module String) [ (ps.target, ps.hfsp_score) ]
  in
  List.fold scores
    ~init:(Map.empty (module String))
    ~f:(fun top_scores pair_score ->
      match pair_score with
      | Ok ps -> Map.update top_scores ps.query ~f:(update_scores ps)
      | Error err ->
          prerr_endline @@ Error.to_string_hum err;
          top_scores)

let print_pair_top_scores top_scores =
  Map.iteri top_scores ~f:(fun ~key:query ~data:scores ->
      Map.iteri scores ~f:(fun ~key:target ~data:score ->
          print_endline [%string "%{query}\t%{target}\t%{score#Float}"]))

type method_ = Overall_top | Pair_top

let method_of_string s =
  let open Or_error in
  match s with
  | "overall" | "Overall" -> return Overall_top
  | "pair" | "Pair" -> return Pair_top
  | _ -> errorf "Expected [Oo]verall|[Pp]air.  Got %s" s

let run method_ fname =
  let scores = parse_search_file fname in
  match method_ with
  | Overall_top -> print_overall_top_scores @@ get_overall_top_scores scores
  | Pair_top -> print_pair_top_scores @@ get_pair_top_scores scores
