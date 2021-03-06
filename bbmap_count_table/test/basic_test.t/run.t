With no arguments

  $ bbmap_count_table 2> err
  [1]
  $ sed -E 's/(bbmap_count_table version).*/\1 REDACTED/' err
  ERROR -- you need at least 2 command line arguments!
  
  bbmap_count_table version REDACTED
  
  usage: bbmap_count_table <sample_name_match> <covstats_1> [covstats_2 ...]
  
  Prints to stdout.
  
  sample_name_match should be a string specifying a regex used to pull
  the sample name from covstats file name.  E.g., if you file names are
  like contigs.mapping___sample_1___.covstats.tsv, then you could pass
  in 'mapping___(.*)___'.
  
  Outputs (plus_reads + minus_reads) / seq_length * 1000 for each sample.  
  Does NOT weight by sample size.  I expect you to use CLR transform or 
  something similar in R before use.
  

With one arg

  $ bbmap_count_table apple 2> err
  [1]
  $ sed -E 's/(bbmap_count_table version).*/\1 REDACTED/' err 
  ERROR -- you need at least 2 command line arguments!
  
  bbmap_count_table version REDACTED
  
  usage: bbmap_count_table <sample_name_match> <covstats_1> [covstats_2 ...]
  
  Prints to stdout.
  
  sample_name_match should be a string specifying a regex used to pull
  the sample name from covstats file name.  E.g., if you file names are
  like contigs.mapping___sample_1___.covstats.tsv, then you could pass
  in 'mapping___(.*)___'.
  
  Outputs (plus_reads + minus_reads) / seq_length * 1000 for each sample.  
  Does NOT weight by sample size.  I expect you to use CLR transform or 
  something similar in R before use.
  

With a single sample.

  $ bbmap_count_table 'mapping___(.*)___' contigs.mapping___sample_1___.covstats.txt
  contig	sample_1
  Contig_1	11000.
  Contig_2	2200.
  Contig_3	330.

With multiple samples

  $ bbmap_count_table 'mapping___(.*)___' contigs.mapping___sample_1___.covstats.txt contigs.mapping___sample_2___.covstats.txt contigs.mapping___sample_3___.covstats.txt
  contig	sample_1	sample_2	sample_3
  Contig_1	11000.	0.	0.
  Contig_2	2200.	220000.	0.
  Contig_3	330.	33000.	0.
  Contig_4	0.	4400.	0.
  Contig_5	0.	0.	55000.

With bad pattern

  $ bbmap_count_table apple contigs.mapping___sample_1___.covstats.txt 2> err
  [2]
  $ sh clean_err.sh err
  Uncaught exception:
    
    Re2__Regex.Exceptions.Regex_no_such_subpattern(1, 1)

One file is missing the pattern.

  $ bbmap_count_table 'mapping___(.*)___' contigs.mapping___sample_1___.covstats.txt missing_pattern.txt 2> err
  [2]
  $ sh clean_err.sh err
  Uncaught exception:
    
    Re2__Regex.Exceptions.Regex_match_failed("mapping___(.*)___")

Duplicated contigs

  $ bbmap_count_table 'mapping___(.*)___' contigs.mapping___sample_1___.covstats.txt contigs.mapping___sample_11___.covstats.txt 2> err
  [2]
  $ sh clean_err.sh err
  Uncaught exception:
    
    ("Error processing stats_file contigs.mapping___sample_11___.covstats.txt"
     "Contig_1 is duplicated in sample_11")
