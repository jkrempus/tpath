/usr/local/bin/bison -d -v tpath.yy ;
/usr/local/bin/flex tpath.lex ;
g++ -std=c++11 main.cpp tpath.tab.cc lex.yy.c lex.yy.o -ll -g -I. -O2
