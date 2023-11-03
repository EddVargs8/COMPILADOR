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
int error_counter = 0; // Contador de errores global
int currentScope = 0; // Contador para llevar un seguimiento de los ámbitos


// Estructura para una entrada de tabla de símbolos
typedef struct SymbolEntry {
    char* name;              // Nombre del identificador
    char* type;              // Tipo del identificador
    int scope;               // Ámbito del identificador
    struct SymbolEntry* entry;         // Entrada de símbolo
    struct SymbolEntry* next;  // Siguiente nodo en la lista enlazada
} SymbolEntry;

// Definición de la estructura para una instrucción de tres direcciones
struct TACInstruction {
    char* operation;   // Cadena que representa la operación (por ejemplo, "+", "*", "=")
    char* result;      // Variable que recibe el resultado de la operación
    char* operand1;    // Primer operando
    char* operand2;    // Segundo operando (puede ser NULL si la operación es unaria)
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
        printf("Operacion: %s, Resultado: %s, Operando1: %s, Operando2: %s\n",
            instruction.operation, instruction.result, instruction.operand1, instruction.operand2);

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
%token IMPRESION OP_ARITMETICO LECTURA ESCRITURA CICLO OP_LOGICO PREGUNTA_CONTRARIA PREGUNTA PORCT PAR_IZ PAR_DE COR_IZ COR_DE ASIGNACION
%%

programa : instrucciones 
        ; 

preguntaIf : PREGUNTA comparacion bloque preguntaElse {}
            ;

preguntaElse : PREGUNTA_CONTRARIA bloque
               | PREGUNTA_CONTRARIA preguntaIf
               | /* vacio */
               ;

comparacion : ID OP_RELACIONAL ID { if (existeTODO($1, $3) == 0) {
                                        struct TACInstruction cmpInstruction;
                                        char *resultado = malloc(strlen("compare") + strlen($2) + 1); // Asegúrate de asignar suficiente memoria
                                        strcpy(resultado, "compare ");
                                        strcat(resultado, $2);
                                        cmpInstruction.operation = resultado;     
                                        cmpInstruction.result = "temp1";      
                                        cmpInstruction.operand1 = $1;     
                                        cmpInstruction.operand2 = $3;    
                                        addInstructionToList(&head, cmpInstruction);            
                                    }
                                    else {
                                    
                                        
                                    }
}
            | ID OP_RELACIONAL NUMERO {if (existeID ($1) == 0) {
                                        SymbolEntry* existingEntry = findInSymbolTable($1, symbolTable);
                                            if ( (strcmp(existingEntry->type, "float") == 0) || (strcmp(existingEntry->type, "double") == 0) || (strcmp(existingEntry->type, "int") == 0) ) {
                                                if (existingEntry->scope <= currentScope) { //Todo correcto
                                                    struct TACInstruction cmpInstruction;
                                                    char *resultado = malloc(strlen("compare") + strlen($2) + 1); // Asegúrate de asignar suficiente memoria
                                                    strcpy(resultado, "compare ");
                                                    strcat(resultado, $2);
                                                    cmpInstruction.operation = resultado;     
                                                    cmpInstruction.result = "temp1";      
                                                    cmpInstruction.operand1 = $1;     
                                                    cmpInstruction.operand2 = $3;    
                                                    addInstructionToList(&head, cmpInstruction); 
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
                                        struct TACInstruction cmpInstruction;
                                        char *resultado = malloc(strlen("compare") + strlen($2) + 1); // Asegúrate de asignar suficiente memoria
                                        strcpy(resultado, "compare ");
                                        strcat(resultado, $2);
                                        cmpInstruction.operation = resultado;     
                                        cmpInstruction.result = "temp1";      
                                        cmpInstruction.operand1 = $1;     
                                        cmpInstruction.operand2 = $3;    
                                        addInstructionToList(&head, cmpInstruction);
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

expresion : termino
          | expresion OP_ARITMETICO termino { }
          ; 

termino : NUMERO
       | PAR_IZ expresion PAR_DE {  }
       ;

lectura : LECTURA ID {}
        ; 

escritura : ESCRITURA ID 
        ; 

mientras : CICLO comparacion bloque {}
        ; 

declaracion : TIPODATO ID { addToSymbolTable($2, $1); 
                             // Crear una instrucción de declaración: int x;
                            struct TACInstruction declarationInstruction;
                            declarationInstruction.operation = "declare";  // Puedes usar una etiqueta como "declare" para representar declaraciones
                            declarationInstruction.result = $2;           // Variable que se está declarando
                            declarationInstruction.operand1 = $1;      // Tipo de la variable
                            declarationInstruction.operand2 = NULL;        // No se utiliza en una declaración                       
                            
                            addInstructionToList(&head, declarationInstruction);
                            }
        ; 

bloque : parte_iz parte_media parte_der
        ; 

parte_iz : COR_IZ {openScope();}
        ; 
        
parte_media : instrucciones 

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
                                                struct TACInstruction assignmentInstruction;
                                                assignmentInstruction.operation = "assign";     // Operación de asignación
                                                assignmentInstruction.result = $1;      // Variable de destino
                                                assignmentInstruction.operand1 = $3;     // Variable fuente
                                                assignmentInstruction.operand2 = NULL;    // No se utiliza en operación de asignación
                                                addInstructionToList(&head, assignmentInstruction);
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
                                            struct TACInstruction assignmentInstruction;
                                            assignmentInstruction.operation = "assignment";     // Operación de asignación
                                            assignmentInstruction.result = $1;      // Variable de destino
                                            assignmentInstruction.operand1 = $3;     // Variable fuente
                                            assignmentInstruction.operand2 = NULL;    // No se utiliza en operación de asignación
                                            addInstructionToList(&head, assignmentInstruction);
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
                                            struct TACInstruction assignmentInstruction;
                                            assignmentInstruction.operation = "assign";     // Operación de asignación
                                            assignmentInstruction.result = $1;      // Variable de destino
                                            assignmentInstruction.operand1 = $3;     // Variable fuente
                                            assignmentInstruction.operand2 = NULL;    // No se utiliza en operación de asignación
                                            addInstructionToList(&head, assignmentInstruction);
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
                                            struct TACInstruction assignmentInstruction;
                                            assignmentInstruction.operation = "assign";     // Operación de asignación
                                            assignmentInstruction.result = $1;      // Variable de destino
                                            assignmentInstruction.operand1 = $3;     // Variable fuente
                                            assignmentInstruction.operand2 = NULL;    // No se utiliza en operación de asignación
                                            addInstructionToList(&head, assignmentInstruction);
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
        | expresion
        ; 

%%

int main() {
    FILE* inputFile = fopen("Datos.txt", "r");
    if (!inputFile) {
        printf("Error al abrir el archivo de entrada.\n");
        return 1;
    }
    
    yyin = inputFile;
    yyparse();
    
    fclose(inputFile);
    if (error_counter == 0) {
        printf("Compilacion exitosa :).\n");
    }

    traverseInstructionList(head); 

    return 0;
}


void yyerror(const char *msg) {
    fprintf(stderr, "Error encontrado: %s. Token: %s\n", msg, yytext);
    error_counter++;
}
