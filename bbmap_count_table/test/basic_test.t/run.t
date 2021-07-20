With no arguments

  $ bbmap_count_table
  ERROR -- you need at least 2 command line arguments!
  
  bbmap_count_table v1.0
  
  usage: bbmap_count_table <sample_name_match> <covstats_1> [covstats_2 ...]
  
  Prints to stdout.
  
  sample_name_match should be a string specifying a regex used to pull
  the sample name from covstats file name.  E.g., if you file names are
  like contigs.mapping___sample_1___.covstats.tsv, then you could pass
  in 'mapping___(.*)___'.
  
  [1]

With one arg

  $ bbmap_count_table apple  
  ERROR -- you need at least 2 command line arguments!
  
  bbmap_count_table v1.0
  
  usage: bbmap_count_table <sample_name_match> <covstats_1> [covstats_2 ...]
  
  Prints to stdout.
  
  sample_name_match should be a string specifying a regex used to pull
  the sample name from covstats file name.  E.g., if you file names are
  like contigs.mapping___sample_1___.covstats.tsv, then you could pass
  in 'mapping___(.*)___'.
  
  [1]

With a single sample.

  $ bbmap_count_table 'mapping___(.*)___' contigs.mapping___sample_1___.covstats.txt
  sample	Contig_1	Contig_2	Contig_3
  sample_1	11	22	33

With multiple samples

  $ bbmap_count_table 'mapping___(.*)___' contigs.mapping___sample_1___.covstats.txt contigs.mapping___sample_2___.covstats.txt contigs.mapping___sample_3___.covstats.txt
  sample	Contig_1	Contig_2	Contig_3	Contig_4	Contig_5
  sample_1	11	22	33	0	0
  sample_2	0	22	33	44	0
  sample_3	0	0	0	0	55

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
