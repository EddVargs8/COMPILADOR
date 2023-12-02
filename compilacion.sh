flex lexico.l
bison -d sintactico.y
gcc -c -o lex.yy.o lex.yy.c
gcc -c -o sintactico.tab.o sintactico.tab.c
clang -o steins lex.yy.o sintactico.tab.o -I/usr/lib/llvm-14/include $(llvm-config --cflags --ldflags --libs)
./steins 