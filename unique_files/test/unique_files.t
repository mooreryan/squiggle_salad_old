Make some files.

  $ echo hi > hi1.txt
  $ echo hi > hi2.txt
  $ echo hi > hi3.txt
  $ echo bye > bye1.txt
  $ echo bye > bye2.txt

Get unique files.

  $ ../unique_files.exe hi*txt bye*txt | cut -f2-
  hi1.txt	hi2.txt	hi3.txt
  bye1.txt	bye2.txt
