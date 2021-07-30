open! Core_kernel
open Bio_io

exception Bad_aln_length of string [@@deriving sexp]

let gap_char = Re2.create_exn "[^a-zA-Z]"
let is_gap_char c = Re2.matches gap_char (String.of_char c)

let make_position_map aligned_seq =
  let _, map =
    String.to_array aligned_seq
    |> Array.foldi
         ~init:(0, Map.empty (module Int))
         ~f:(fun aln_column (seq_position, map) char ->
           if is_gap_char char then (seq_position, map)
           else
             ( seq_position + 1,
               (* _exn is okay here as new_seq_position is always increasing. *)
               Map.add_exn map ~key:seq_position ~data:aln_column ))
  in
  map

let bad_aln_length_exn seq_i expected_len actual_len =
  let i = seq_i + 1 in
  Bad_aln_length
    [%string
      "Seq num: %{i#Int}, Expected length: %{expected_len#Int}, Actual length: \
       %{actual_len#Int}"]

type alignment_file_data = {
  position_map : (int, int, Int.comparator_witness) Map.t;
  records : Fasta_record.t list;
  alignment_length : int;
  num_records : int;
}

let empty_alignment_data () =
  {
    position_map = Map.empty (module Int);
    records = [];
    alignment_length = 0;
    num_records = 0;
  }

let parse_alignment_file infile =
  let f () =
    Fasta_in_channel.with_file_foldi_records_exn infile
      ~init:(empty_alignment_data ()) ~f:(fun i aln record ->
        let this_aln_len = String.length (Fasta_record.seq record) in
        if i = 0 then
          let position_map = make_position_map (Fasta_record.seq record) in
          {
            position_map;
            records = record :: aln.records;
            alignment_length = this_aln_len;
            num_records = 1;
          }
        else if this_aln_len = aln.alignment_length then
          {
            aln with
            num_records = aln.num_records + 1;
            records = record :: aln.records;
          }
        else raise @@ bad_aln_length_exn i aln.alignment_length this_aln_len)
  in
  match f () with
  (* Catches every exception. *)
  | exception exn ->
      Or_error.of_exn exn |> Or_error.tag ~tag:"Error parsing alignment"
  | aln -> Or_error.return { aln with records = List.rev aln.records }

let print_columns_info infile positions =
  let open Or_error.Let_syntax in
  let header =
    let posns = List.map positions ~f:(fun i -> "pos_" ^ Int.to_string i) in
    "name\t" ^ String.concat posns ~sep:"\t" ^ "\tsignature"
  in
  print_endline header;
  let positions_zero_indexed =
    List.map positions ~f:(fun position -> position - 1)
  in
  let%bind aln_info = parse_alignment_file infile in
  let aln = Array.of_list aln_info.records in
  (* These are the key residues indices w.r.t. to aligned sequences. *)
  let%map aln_columns =
    List.map positions_zero_indexed ~f:(fun position ->
        Map.find_or_error aln_info.position_map position)
    |> Or_error.all
  in
  Array.iter aln ~f:(fun record ->
      let id = Fasta_record.id record in
      let seq = Fasta_record.seq record in
      let key_residues =
        List.map aln_columns ~f:(fun col_i ->
            String.of_char @@ String.get seq col_i)
      in
      let signature = String.concat key_residues ~sep:"" in
      let key_residues' = String.concat key_residues ~sep:"\t" in
      let line = [%string "%{id}\t%{key_residues'}\t%{signature}"] in
      print_endline line)

let run infile positions =
  match
    print_columns_info infile positions
    |> Or_error.tag ~tag:"Error in print_columns_info"
  with
  | Ok () -> ()
  | Error err ->
      prerr_endline @@ Error.to_string_hum err;
      exit 1
