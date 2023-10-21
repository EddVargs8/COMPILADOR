# COMPILADOR

Compilar usando: 

flex lexico.l                
bison -d -t sintactico.y     
gcc lex.yy.c sintactico.tab.c
.\a  

El programa asume que tienes un archivo de datos llamado Datos.txt el cual será el input para el programa
