open! Core_kernel

let version = "0.1.0"

let usage_msg =
  {eof|usage: bbmap_count_table <sample_name_match> <covstats_1> [covstats_2 ...]

Prints to stdout.

sample_name_match should be a string specifying a regex used to pull
the sample name from covstats file name.  E.g., if you file names are
like contigs.mapping___sample_1___.covstats.tsv, then you could pass
in 'mapping___(.*)___'.

Outputs (plus_reads + minus_reads) / seq_length * 1000 for each sample.  
Does NOT weight by sample size.  I expect you to use CLR transform or 
something similar in R before use.
|eof}

let help_msg = [%string "bbmap_count_table v%{version}\n\n%{usage_msg}"]

let parse_args () =
  let args = Sys.argv in
  (* First arg is program name. *)
  if Array.length args < 3 then
    let msg =
      "ERROR -- you need at least 2 command line arguments!\n\n" ^ help_msg
    in
    Lib.abort msg
  else
    let pattern = args.(1) in
    let infiles = Array.slice args 2 0 in
    (pattern, infiles)

let pattern, infiles = parse_args ()

let () = Lib.run pattern infiles
