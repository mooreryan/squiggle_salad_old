open! Core_kernel
open Hfsp

let version = "0.1.0"

let usage_msg =
  {eof|usage: hfsp <method: overall|pair> <search_out.tsv> > out.tsv

"Best" means hit with highest bit score.  HFSP is only calculated on 
  "best" hits.  overall|pair controls which "best" hits to report.

overall -- Only one score is printed per query.  It is the score to 
  the best target. 

pair -- One score is printed for each query-target pair.  It is the 
  best score for each query-target pair.

Don't forget to run mmseqs2 with 
  --format-output query,target,fident,bits,cigar
|eof}

let help_msg = [%string "hfsp v%{version}\n\n%{usage_msg}"]

let parse_args () =
  let args = Sys.argv in
  (* First arg is program name. *)
  if Array.length args < 3 then
    let msg =
      "ERROR -- you need at least 2 command line arguments!\n\n" ^ help_msg
    in
    Utils.abort msg
  else
    let method_ = Lib.method_of_string args.(1) |> Or_error.ok_exn in
    let infile = args.(2) in
    (method_, infile)

let method_, infile = parse_args ()

let () = Lib.run method_ infile
