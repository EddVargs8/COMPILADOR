%{
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
extern int yylineno; // Variable global para el número de línea
extern char* yytext; // Variable global para el texto del token
int yylex();
void yyerror(const char *msg);
extern FILE* yyin;
FILE* outputFile;
int error_counter = 0; // Contador de errores global
int currentScope = 0; // Contador para llevar un seguimiento de los ámbitos
int tempVarCounter = 1; // Contador de variables temporales 
int labelCounter = 1; 
int esCiclo = 0; 

// Estructura para una entrada de tabla de símbolos
typedef struct SymbolEntry {
    char* name;              // Nombre del identificador
    char* type;              // Tipo del identificador
    int scope;               // Ámbito del identificador
    struct SymbolEntry* entry;         // Entrada de símbolo
    struct SymbolEntry* next;  // Siguiente nodo en la lista enlazada
} SymbolEntry;

// Definición de la estructura para una instrucción de codigo intermedio
struct TACInstruction {
    char* instruccion;  
};

struct TACList {
    struct TACInstruction instruction;
    struct TACList* next;
};

// Puntero al primer nodo de la tabla de símbolos
SymbolEntry* symbolTable = NULL;
struct TACList* head = NULL;  // Inicializa la lista vacía 

void addInstructionToList(struct TACList** list, struct TACInstruction instruction) {
    // Crear un nuevo nodo
    struct TACList* newNode = (struct TACList*)malloc(sizeof(struct TACList));
    newNode->instruction = instruction;
    newNode->next = NULL;

    if (*list == NULL) {
        // Si la lista está vacía, el nuevo nodo será la cabeza de la lista
        *list = newNode;
    } else {
        // Si la lista no está vacía, encontrar el último nodo y agregar el nuevo nodo al final
        struct TACList* current = *list;
        while (current->next != NULL) {
            current = current->next;
        }
        current->next = newNode;
    }
}

void traverseInstructionList(struct TACList* list) {
    struct TACList* current = list;

    while (current != NULL) {
        // Acceder a la instrucción actual
        struct TACInstruction instruction = current->instruction;

        // Realizar acciones con la instrucción, por ejemplo, imprimir
        fprintf(outputFile, "%s\n", instruction.instruccion);
        
        // Avanzar al siguiente nodo
        current = current->next;
    }
}


SymbolEntry* findInSymbolTable(const char* name, SymbolEntry* symbolTable) {
    SymbolEntry* currentEntry = symbolTable; 

    while (currentEntry != NULL) {
        if (strcmp(currentEntry->name, name) == 0)
            return currentEntry; 
        currentEntry = currentEntry->next; 
    }
    return NULL; 
}

// Función para agregar una entrada a la tabla de símbolos
void addToSymbolTable(const char* name, const char* type) {
    SymbolEntry* existingEntry = findInSymbolTable(name, symbolTable);
        
        if (existingEntry == NULL) {
            SymbolEntry* newNode = (SymbolEntry*)malloc(sizeof(SymbolEntry));
            newNode->name = strdup(name);
            newNode->type = strdup(type);
            newNode->scope = currentScope; // Establece el ámbito actual
            newNode->next = symbolTable;
            symbolTable = newNode; 
        } else {
            fprintf(stderr, "Error: La variable %s ya se declaro previamente. ",name);
            error_counter++; 
            // exit(EXIT_FAILURE);
        }
             
}

void deleteIdentifier(SymbolEntry** symbolTable, const char* identifierToDelete) {
    SymbolEntry* current = *symbolTable;
    SymbolEntry* previous = NULL;

    // Recorre la lista en busca del identificador
    while (current != NULL) {
        // Compara el identificador actual con el identificador a eliminar
        if (strcmp(current->name, identifierToDelete) == 0) {
            // Si se encuentra el identificador, se debe eliminar el nodo
            if (previous == NULL) {
                // Si es el primer nodo, actualiza la cabeza de la lista
                *symbolTable = current->next;
            } else {
                previous->next = current->next;
            }
            // Libera la memoria de los campos name y type
            free(current->name);
            free(current->type);
            // Libera la memoria del nodo eliminado
            free(current);
            return; // Termina la función
        }

        // Avanza al siguiente nodo
        previous = current;
        current = current->next;
    }
}

char* createTempVar() {
    char* tempVar = (char*)malloc(10); // Asigna espacio para una cadena de hasta 10 caracteres
    snprintf(tempVar, 10, "t%d", tempVarCounter++);
    return tempVar;
}

char* createNewLabel() {
    char* label = (char*)malloc(10);
    snprintf(label, 10, "L%d", labelCounter++);
    return label;
}

char* createDeclaration (char* tipoda, char* ide) {
    char* declaration = (char *)malloc(strlen(tipoda) + strlen(ide) + 1); 
    strcpy(declaration, tipoda);
    strcat(declaration, " ");
    strcat(declaration, ide); 
    return declaration; 
}

char* createAsignation (char* tempVar, char* op1, char* operator, char* op2) {
    int bufferSize = 100;
    char* buffer = (char*)malloc(bufferSize); 

    snprintf(buffer, bufferSize, "%s = %s %s %s\n", tempVar, op1, operator, op2);
    return buffer; 
}

char* createSimpleAsignation (char* id, int varTemp) {
    int bufferSize = 100;
    char* buffer = (char*)malloc(bufferSize); 

    snprintf(buffer, bufferSize, "%s = t%d\n", id, varTemp);

    return buffer; 
}

char* generateInterCode(const char* op1, const char* operator, const char* op2) {
    char* tempVar = createTempVar();
    if (esCiclo == 0) {
        fprintf(outputFile, "%s = %s %s %s\n", tempVar, op1, operator, op2);
    }
    return tempVar;
}

int existeID (char* name) {
    SymbolEntry* id = findInSymbolTable(name, symbolTable);
    if (id == NULL) {
        return 1; //Encontro error
    }
    else 
        return 0; 
}

//Metodo que recibe como parametro un ID y un tipo con el que comparar
int sisTipos(char* name, char* type) { 
    SymbolEntry* existingEntry = findInSymbolTable(name, symbolTable);
    char* currentType = existingEntry->type;  

    // ENTEROS
    if ( (strcmp(currentType, "int") == 0) && ( (strcmp(type, "float") == 0) || (strcmp(type, "double") == 0) ) ) { //Match
        printf("Advertencia: Perdida de datos. Tipo entero y flotante "); 
        return 1;  
    } else if ( (strcmp(currentType, "int") == 0) && ( (strcmp(type, "char") == 0) || (strcmp(type, "boolean") == 0) || (strcmp(type, "string") == 0) ) ) {
        printf("Error tipos de datos incompatibles.");
        error_counter++;  
        return 1; 
    }
    //FLOAT
    if ( (strcmp(currentType, "float") == 0) && ( (strcmp(type, "boolean") == 0) || (strcmp(type, "char") == 0) || (strcmp(type, "string") == 0) ) ) { //Match
        printf("Error tipos de datos incompatibles"); 
        error_counter++; 
        return 1;  
    } else if ( (strcmp(currentType, "float") == 0) && ( (strcmp(type, "int") == 0) ) ) { //Match
        printf("Advertencia: Perdida de datos. Tipo flotante y entero "); 
        return 1;
    }

    //DOUBLE
    if ( (strcmp(currentType, "double") == 0) && ( (strcmp(type, "boolean") == 0) || (strcmp(type, "char") == 0) || (strcmp(type, "string") == 0) ) ) { //Match
        printf("Error tipos de datos incompatibles"); 
        error_counter++; 
        return 1;  
    } else if ( (strcmp(currentType, "double") == 0) && ( (strcmp(type, "int") == 0) ) ) { //Match
        printf("Advertencia: Perdida de datos. Tipo double y entero "); 
        return 1;
    }

    //CHAR
    if ( (strcmp(currentType, "char") == 0) && ( (strcmp(type, "boolean") == 0) || (strcmp(type, "int") == 0) || (strcmp(type, "float") == 0) || (strcmp(type, "double") == 0) || (strcmp(type, "string") == 0) || (strcmp(type, "char") == 0) ) ) { //Match
        printf("Error tipos de datos incompatibles"); 
        error_counter++; 
        return 1;  
    } 

    //BOOLEAN
    if ( (strcmp(currentType, "boolean") == 0) && ( (strcmp(type, "char") == 0) || (strcmp(type, "int") == 0) || (strcmp(type, "float") == 0) || (strcmp(type, "double") == 0) || (strcmp(type, "string") == 0) ) ) { //Match
        printf("Error tipos de datos incompatibles"); 
        error_counter++; 
        return 1;  
    }

    //STRING 
    if ( (strcmp(currentType, "string") == 0) && ( (strcmp(type, "int") == 0) || (strcmp(type, "double") == 0) || (strcmp(type, "boolean") == 0) || (strcmp(type, "float") == 0)) ) { //Match
        printf("Error tipos de datos incompatibles"); 
        error_counter++; 
        return 1;  
    } 
    
    return 0; 
}

int existeTODO(char* name1, char* name2) {
    SymbolEntry* id1 = findInSymbolTable(name1, symbolTable); 
    SymbolEntry* id2 = findInSymbolTable(name2, symbolTable); 
     
    if (existeID(name1) == 1) {
        printf("Error: La variable %s no se ha declarado previamente. \n", name1);
        error_counter++; 
        return 1; //Encontro error
    }     
    else if (existeID(name2) == 1) {
        printf("Error: La variable %s no se ha declarado previamente. \n", name2);
        error_counter++;
        return 1; //Encontro error
    }    
    else if (strcmp(id1->type, id2->type) != 0) {
        printf("Error: Los tipos de las variables %s y %s no coinciden. \n", name1, name2); 
        error_counter++; 
        return 1; //Encontro error
    } 
    else if ( (id1->scope > currentScope) && (id2->scope > currentScope)) {
        printf("Error: Los ambitos de las variables %s y %s no coinciden. \n", name1, name2);
        error_counter++; 
        return 1; //Encontro error
    }
    return 0;  // No encontro error  
}

void openScope() {
    currentScope++;
}

// Función para cerrar el ámbito actual (por ejemplo, al salir de una función)
void closeScope() {
    currentScope--;
}

%}

%union {
    char* cadena;
}

%token <cadena> ID 
%token <cadena> TIPODATO 
%token <cadena> NUMERO
%token <cadena> ESTADO
%token <cadena> OP_RELACIONAL
%token <cadena> OP_ARITMETICO
%token IMPRESION  LECTURA ESCRITURA CICLO OP_LOGICO PREGUNTA_CONTRARIA PREGUNTA PORCT PAR_IZ PAR_DE COR_IZ COR_DE ASIGNACION
%left OP_ARITMETICO
%type <cadena> stmt assignment arith_expr term factor instruccion instrucciones comparacion declaracion parte_media bloque mientrasToken
%%

programa : instrucciones {}
        ; 

preguntaIf : PREGUNTA comparacion bloque preguntaElse {}
            ;

preguntaElse : PREGUNTA_CONTRARIA bloque
               | PREGUNTA_CONTRARIA preguntaIf
               | /* vacio */
               ;

comparacion : ID OP_RELACIONAL ID { if (existeTODO($1, $3) == 0) {
                                       $$ = strcat(strcat(strdup($1),$2),strdup($3));  
                                    }
                                    else {
                                    
                                        
                                    }
}
            | ID OP_RELACIONAL NUMERO {if (existeID ($1) == 0) {
                                        SymbolEntry* existingEntry = findInSymbolTable($1, symbolTable);
                                            if ( (strcmp(existingEntry->type, "float") == 0) || (strcmp(existingEntry->type, "double") == 0) || (strcmp(existingEntry->type, "int") == 0) ) {
                                                if (existingEntry->scope <= currentScope) { //Todo correcto
                                                    
                                                } else {
                                                 printf("Error: Variable %s no existe en el ambito actual. \n", existingEntry->name);
                                                    error_counter++; 
                                                }
                                            }
                                            else {
                                                printf("Error de compilacion: variable %s tipos de datos incompatibles\n", $1);
                                                error_counter++;  
                                            }
                                    }
                                    else {
                                        printf("Error de compilacion, variable %s no ha sido declarada\n", $1); 
                                        error_counter++;
                                    }
            
}
            | ID OP_RELACIONAL ESTADO { if (existeID ($1) == 0) {
                                    SymbolEntry* existingEntry = findInSymbolTable($1, symbolTable);
                                    if ( (strcmp(existingEntry->type, "boolean") == 0) ) {
                                        
                                    }
                                    else {
                                        printf("Error de compilacion: variable %s tipos incompatibles\n", $1);
                                        error_counter++;  
                                    }
                                }
                                else {
                                    printf("Error de compilacion, variable %s no ha sido declarada\n", $1); 
                                    error_counter++;
                                }
            }
            ;

aritmetica : ID OP_ARITMETICO ID { if (existeTODO($1, $3) == 0) {
                                    SymbolEntry* id1 = findInSymbolTable($1, symbolTable); 
                                    SymbolEntry* id2 = findInSymbolTable($3, symbolTable);
                                        if ( (strcmp(id1->type, "float") == 0) || (strcmp(id1->type, "double") == 0) || (strcmp(id1->type, "int") == 0) || (strcmp(id2->type, "float") == 0) || (strcmp(id2->type, "double") == 0) || (strcmp(id2->type, "int") == 0) ) {
                                                
                                        }
                                        else {
                                                    printf("Error de compilacion: tipos de datos incompatibles\n", $1);
                                                    error_counter++;  
                                        }    
                                    }
                                else {
                                     
                                        
                                }

 }   

lectura : LECTURA ID {}
        ; 

escritura : ESCRITURA ID 
        ; 

mientrasToken : CICLO comparacion {
        esCiclo = 1;
        $$ = $2; 
    } 
    ; 

mientras : mientrasToken bloque { 
        char* whileStartLabel = createNewLabel();
        char* whileEndLabel = createNewLabel();
        fprintf(outputFile, "%s: ", whileStartLabel);
        fprintf(outputFile, "if %s goto %s\n", $1, whileEndLabel);
        fprintf(outputFile, "goto L%d\n", labelCounter);
        fprintf(outputFile, "%s: ", whileEndLabel); 
            // Cuerpo del bucle
        traverseInstructionList(head); 

        fprintf(outputFile, "goto %s\n", whileStartLabel);
        esCiclo = 0; 
        char* OutOfWhileLabel = createNewLabel();
        fprintf(outputFile, "%s: ", OutOfWhileLabel);
        
        free(whileStartLabel);
        free(whileEndLabel);
}
        ; 

declaracion : TIPODATO ID { addToSymbolTable($2, $1); 
                                if (esCiclo == 1) {
                                    struct TACInstruction insDecl;
                                    insDecl.instruccion = createDeclaration($1, $2);
                                    addInstructionToList(&head, insDecl);
                                }
                                else {
                                    fprintf(outputFile, "%s %s\n", $1, $2); 
                                }
                            }
        ; 

bloque : parte_iz parte_media parte_der {         
        }
        ; 

parte_iz : COR_IZ {openScope();}
        ; 
        
parte_media : instrucciones { 
                            
                            }
        ; 

parte_der : COR_DE { // RECORRE LISTA PARA ENCONTRAR ID QUE SE CREARON EN CURRENTSCOPE
                    SymbolEntry* currentEntry = symbolTable; 
                    SymbolEntry* temp; 

                    while (currentEntry != NULL) {
                        if (currentEntry->scope == currentScope) {
                            temp = currentEntry->next; 
                            deleteIdentifier(&symbolTable, currentEntry->name);
                            currentEntry = temp; 
                        }   
                        currentEntry = currentEntry->next;       
                    }
                    closeScope();
                    }
        ; 

asignacion : ID ASIGNACION ID {   SymbolEntry* existingEntry = findInSymbolTable($3, symbolTable); 
                                    if (existingEntry ==  NULL) { //Es cadena
                                        if (existeID ($1) == 0) {
                                            SymbolEntry* existingEntry = findInSymbolTable($1, symbolTable);
                                            if ( (strcmp(existingEntry->type, "string") == 0)  ) { //Cadena con cadena

                                                fprintf(outputFile, "%s = %s\n", $1, $3); 
                                            }
                                            else {
                                                fprintf(stderr, "Error de compilacion: variable %s tipos incompatibles\n", $1);
                                                error_counter++;
                                                //exit(EXIT_FAILURE); 
                                            }
                                        }
                                        else {
                                            printf("Error de compilacion: variable %s no ha sido declarada\n", $1); 
                                            error_counter++;
                                        }
                                    }
                                    else { // Son 2 ID 
                                        if (sisTipos($1, existingEntry->type) == 1) { 

                                            fprintf(outputFile, "%s = %s\n", $1, $3);    
                                        }
                                        else {                                        
                                         
                                        }
                                    }                                  
}
        | ID ASIGNACION NUMERO { if (existeID ($1) == 0) {
                                    SymbolEntry* existingEntry = findInSymbolTable($1, symbolTable);
                                    if ( (strcmp(existingEntry->type, "float") == 0) || (strcmp(existingEntry->type, "double") == 0) || (strcmp(existingEntry->type, "int") == 0) || (strcmp(existingEntry->type, "string") == 0) ) {
                                        // Si la cadena contiene punto y es entera es ERROR
                                        char *resultado = strstr($3, ".");
                                        if ( (resultado != NULL) && (strcmp(existingEntry->type, "int") == 0) ) {
                                            printf("Error: Variable %s datos incompatibles. \n", existingEntry->name);
                                            error_counter++;
                                        }
                                        
                                        if (existingEntry->scope <= currentScope) { //Todo correcto
                                            
                                        } else {
                                            printf("Error: Variable %s no existe en el ambito actual. \n", existingEntry->name);
                                            error_counter++; 
                                        }
                                    }
                                    else {
                                        printf("Error de compilacion: variable %s tipos incompatibles\n", $1);
                                        error_counter++;  
                                    }
                                }                              
                                else {
                                    printf("Error de compilacion: variable %s no ha sido declarada\n", $1); 
                                    error_counter++;
                                }

        }
        | ID ASIGNACION ESTADO { if (existeID ($1) == 0) {
                                    SymbolEntry* existingEntry = findInSymbolTable($1, symbolTable);
                                    if ( (strcmp(existingEntry->type, "boolean") == 0) ) {
                                        if (existingEntry->scope <= currentScope) { //Todo correcto
                                            
                                        } else {
                                            printf("Error: Variable %s no existe en el ambito actual. \n", existingEntry->name);
                                            error_counter++; 
                                        }
                                    }
                                    else {
                                        printf("Error de compilacion: variable %s tipos incompatibles\n", $1);
                                        error_counter++;  
                                    }
                                }
                                else {
                                    printf("Error de compilacion, variable %s no ha sido declarada\n", $1); 
                                    error_counter++;
                                }

        } 
        ;

stmt: assignment
    | arith_expr
    ;

assignment: ID ASIGNACION arith_expr {
            // Genera una nueva variable temporal y asigna el resultado
        char* tempVar = createTempVar(); 
        
        if (esCiclo == 1) { 
            struct TACInstruction insAsigSimp;
            insAsigSimp.instruccion = createSimpleAsignation($1, tempVarCounter-2);
            addInstructionToList(&head, insAsigSimp);
        } else {
            fprintf(outputFile, "%s = t%d\n", $1, tempVarCounter-2);
        }
        tempVarCounter = 1; 
        //free(tempVar); // Libera la memoria
    }
    ;

arith_expr: arith_expr OP_ARITMETICO term {
            $$ = generateInterCode($1, $2, $3);
          }
          | term 
          ;

term: term OP_ARITMETICO factor {
        $$ = generateInterCode($1, $2, $3);
        if (esCiclo == 1) {
            struct TACInstruction insAsig;
            insAsig.instruccion = createAsignation($$, $1, $2, $3);
            addInstructionToList(&head, insAsig);
        } else {
            
        }
    }
    | factor
    ;

factor: NUMERO { $$ = strdup($1); }
      | ID  { $$ = strdup($1); }
      | PAR_IZ arith_expr PAR_DE
      ;


instrucciones : instruccion instrucciones
            | /* vacio */
              ;

instruccion : aritmetica 
        | lectura 
        | comparacion
        | declaracion 
        | asignacion 
        | preguntaIf
        | mientras
        | escritura 
        | stmt
        ; 

%%

int main() {
    FILE* inputFile = fopen("Datos.txt", "r");
    if (!inputFile) {
        printf("Error al abrir el archivo de entrada.\n");
        return 1;
    }
    // Abre el archivo de salida para escribir
    outputFile = fopen("intermedio.txt", "w");
    if (outputFile == NULL) {
        perror("Error al abrir el archivo de salida");
        exit(EXIT_FAILURE);
    }

    yyin = inputFile;
    yyparse();
    
    fclose(inputFile);

    fclose(outputFile);


    if (error_counter == 0) {
        printf("\nCompilacion exitosa :).");
    }

    return 0;
}


void yyerror(const char *msg) {
    fprintf(stderr, "Error encontrado: %s. Token: %s\n", msg, yytext);
    error_counter++;
}
