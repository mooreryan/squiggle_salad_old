No args

  $ check_alignment
  usage: check_alignment <infile> <col_1> [col_2 ...]
  [1]

One arg

  $ check_alignment aln.fa
  usage: check_alignment <infile> <col_1> [col_2 ...]
  [1]

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

  $ check_alignment bad_length.fa 2 4
  name	pos_2	pos_4	signature
  ("Error in print_columns_info"
   ("Error parsing alignment"
    (lib.ml.Bad_aln_length "Seq num: 2, Expected length: 4, Actual length: 3")))
  [1]
