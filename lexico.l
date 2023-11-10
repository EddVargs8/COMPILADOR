%{
#include <stdio.h>
#include "sintactico.tab.h" /* GENERADO AUTOMÁTICAMENTE POR BISON */
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
FILE *yyin; // archivo de entrada

%}

%option yylineno
/*TOKENS*/

PREGUNTA  if|IF
PREGUNTA_CONTRARIA else|ELSE
TIPODATO  int|float|short|long|boolean|byte|char|double|enum|string
OP_LOGICO True|not|false|AND|OR|!
CICLO     while|WHILE
LECTURA   read|READ
EXCRITURA write|WRITE
OP_RELACIONAL  \>=|\>|\==|\<=|\<|\!=
OP_ARITMETICO  \+|\-|\*|\/ 
ASIGNACION \= 
IMPRESION imprime
ESTADO true|false
NUMERO [0-9]+(\.[0-9]+)?  
ID [a-zA-Z0-9_][a-zA-Z0-9_]*
%%

{PREGUNTA} {return (PREGUNTA); }
{PREGUNTA_CONTRARIA} {return (PREGUNTA_CONTRARIA); }
{CICLO} {return (CICLO); }
{LECTURA} {return (LECTURA); }
{OP_RELACIONAL} {yylval.cadena = strdup(yytext); return (OP_RELACIONAL);}
{OP_ARITMETICO} {yylval.cadena = strdup(yytext); return (OP_ARITMETICO); }
"%" {return (PORCT);}
"(" {return (PAR_IZ);}
")" {return (PAR_DE);} 
"{" {return (COR_IZ);}
"}" {return (COR_DE);} 
{ASIGNACION} {return(ASIGNACION); }
{ESTADO} {yylval.cadena = strdup(yytext); return(ESTADO); }
{TIPODATO} { yylval.cadena = strdup(yytext); return(TIPODATO);}
{NUMERO}  {yylval.cadena = strdup(yytext); return NUMERO; }
{ID} { yylval.cadena = strdup(yytext); return ID; }
[\r\n]
%%
int yywrap() {}