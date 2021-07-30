No arguments

  $ hfsp 2> err
  [1]
  $ sed -E 's/(hfsp version).*/\1 REDACTED/' err
  ERROR -- you need at least 2 command line arguments!
  
  hfsp version REDACTED
  
  usage: hfsp <method: overall|pair> <search_out.tsv> > out.tsv
  
  "Best" means hit with highest bit score.  HFSP is only calculated on 
    "best" hits.  overall|pair controls which "best" hits to report.
  
  overall -- Only one score is printed per query.  It is the score to 
    the best target. 
  
  pair -- One score is printed for each query-target pair.  It is the 
    best score for each query-target pair.
  
  Don't forget to run mmseqs2 with 
    --format-output query,target,fident,bits,cigar
  


One argument

  $ hfsp apple 2> err
  [1]
  $ sed -E 's/(hfsp version).*/\1 REDACTED/' err
  ERROR -- you need at least 2 command line arguments!
  
  hfsp version REDACTED
  
  usage: hfsp <method: overall|pair> <search_out.tsv> > out.tsv
  
  "Best" means hit with highest bit score.  HFSP is only calculated on 
    "best" hits.  overall|pair controls which "best" hits to report.
  
  overall -- Only one score is printed per query.  It is the score to 
    the best target. 
  
  pair -- One score is printed for each query-target pair.  It is the 
    best score for each query-target pair.
  
  Don't forget to run mmseqs2 with 
    --format-output query,target,fident,bits,cigar
  

Two args.  First bad.

  $ hfsp thing search.tsv 2> err
  [2]
  $ sh clean_err.sh err
  Uncaught exception:
    
    "Expected [Oo]verall|[Pp]air.  Got thing"

Two args.  Second bad.

  $ hfsp overall thing 2> err
  [2]
  $ sh clean_err.sh err
  Uncaught exception:
    
    (Sys_error "thing: No such file or directory")

Overall best query scores

  $ hfsp overall search.tsv 1> out 2> err
  $ cat out
  q1	t1	57.41094249333792
  q2	t1	57.41094249333792
  q3	t3	57.41094249333792
  $ cat err
  ("Error in line 1"
   ("Error parsing float" (Invalid_argument "Float.of_string pident")))
  ("Error in line 4"
   "Wrong number of tokens when parsing line: 'bad thing\tsilly  '")
  ("Error in line 8"
   ("Error parsing float" (Invalid_argument "Float.of_string qdrw100")))


All pairs best query scores

  $ hfsp pair search.tsv 1> out 2> err
  $ cat out
  q1	t1	57.41094249333792
  q1	t2	57.41094249333792
  q2	t1	57.41094249333792
  q3	t3	57.41094249333792
  $ cat err
  ("Error in line 1"
   ("Error parsing float" (Invalid_argument "Float.of_string pident")))
  ("Error in line 4"
   "Wrong number of tokens when parsing line: 'bad thing\tsilly  '")
  ("Error in line 8"
   ("Error parsing float" (Invalid_argument "Float.of_string qdrw100")))

TODO cigar string with spaces at the end  
