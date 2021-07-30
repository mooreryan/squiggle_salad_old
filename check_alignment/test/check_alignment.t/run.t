No args

  $ check_alignment 2> err
  [1]
  $ sed -E 's/(check_alignment version).*/\1 REDACTED/' err
  check_alignment version REDACTED
  
  usage: check_alignment <infile> <col_1> [col_2 ...]

One arg

  $ check_alignment aln.fa 2> err
  [1]
  $ sed -E 's/(check_alignment version).*/\1 REDACTED/' err
  check_alignment version REDACTED
  
  usage: check_alignment <infile> <col_1> [col_2 ...]

Two args

  $ check_alignment aln.fa 2
  name	pos_2	signature
  s1	C	C
  s2	c	c
  s3	-	-

Three args

  $ check_alignment aln.fa 2 4
  name	pos_2	pos_4	signature
  s1	C	T	CT
  s2	c	t	ct
  s3	-	-	--

Bad alignment

  $ check_alignment bad_length.fa 2 4 2> err
  name	pos_2	pos_4	signature
  [1]
  $ sed -E 's/\(.*(Bad_aln_length.*)/(REDACTED \1/' err | tr '\n' ' ' | sed -E 's/ +/ /g'
  ("Error in print_columns_info" ("Error parsing alignment" (REDACTED Bad_aln_length "Seq num: 2, Expected length: 4, Actual length: 3"))) 

