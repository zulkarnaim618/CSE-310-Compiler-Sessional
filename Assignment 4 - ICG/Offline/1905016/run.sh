#!/bin/bash

yacc -d -y -Wno -Wcounterexamples 1905016.y
echo 'Generated the parser C file as well the header file'
g++ -w -c -o y.o y.tab.c
echo 'Generated the parser object file'
flex 1905016.l
echo 'Generated the scanner C file'
g++ -fpermissive -w -c -o l.o lex.yy.c
# if the above command doesn't work try g++ -fpermissive -w -c -o l.o lex.yy.c
echo 'Generated the scanner object file'
g++ y.o l.o -lfl -o parser
echo 'All ready, running'
echo 'Now run the following command with input filename'
echo './parser input.c'
