open! Core_kernel

exception Cigar_parse_exn of string [@@deriving sexp]

type cigar_op = Match | Deletion | Insertion [@@deriving sexp]
type cigar_pair = { count : int; op : cigar_op } [@@deriving sexp]
type cigar = cigar_pair list [@@deriving sexp]

let cigar_op_of_char c =
  let open Or_error in
  match c with
  | 'M' -> return Match
  | 'D' -> return Deletion
  | 'I' -> return Insertion
  | _ -> errorf "Expected M, D, or I.  Got %c." c

let int_re = Re2.create_exn "[0-9]+"
let cigar_op_re = Re2.create_exn "[MDI]"

let is_int c = Re2.matches int_re (String.of_char c)
let is_cigar_op c = Re2.matches cigar_op_re (String.of_char c)

(* One weird thing is that back to back same operations are allowed. See tests. *)
let parse_cigar_string s =
  let f () =
    let _, pairs =
      String.to_list s
      |> List.fold ~init:("", []) ~f:(fun (current, all) c ->
             match (is_int c, is_cigar_op c) with
             | true, true ->
                 (* Can't be both int and cigar_op *)
                 assert false
             | false, false ->
                 raise
                   (Cigar_parse_exn
                      [%string "Expected int or Operation. Got %{c#Char}"])
             | false, true ->
                 (* You can get an Op without a preceding integer. In this case,
                    treat the count as 1. See
                    https://drive5.com/usearch/manual/cigar.html: "In some CIGAR
                    variants, the integer may be omitted if it is 1." *)
                 let count =
                   if String.(current = "") then 1 else Int.of_string current
                 in
                 let op = cigar_op_of_char c |> Or_error.ok_exn in
                 ("", { count; op } :: all)
             | true, false -> (current ^ String.of_char c, all))
    in
    List.rev pairs
  in
  Utils.try0 ~msg:"Error parsing cigar string" f

(* This is as in https://doi.org/10.1093/bioinformatics/bty262. Where ungapped
   is the alignment length minus number of gaps. I'm taking that to mean any
   position with a gap in either sequence is not counted. So the ungapped_length
   is the number of matches. *)
let ungapped_length cigar =
  List.fold cigar ~init:0 ~f:(fun acc { count; op } ->
      match op with Match -> acc + count | Deletion | Insertion -> acc)
