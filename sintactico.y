%{
//Analizador Sintactico ; Edwin Reyes
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

// Incluye encabezados de LLVM
#include <llvm-c/Core.h>
#include <llvm-c/Analysis.h>
#include <llvm-c/ExecutionEngine.h>
#include <stdio.h>
#include <stdbool.h>

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
int esIf = 0;
int esElse = 0;
int creoLoop = 0;
// Declarar el context global
LLVMContextRef globalContext; 
// Declarar el builder global
LLVMBuilderRef globalBuilder;
// Declarar el bloque básico de entrada 
LLVMBasicBlockRef entryBlock; 
// Declarar el módulo LLVM global
LLVMModuleRef module;
// Declarar la función actual
LLVMValueRef entryFunction; 
LLVMValueRef globalCondition = NULL;
//Bloques para while 
LLVMBasicBlockRef loopConditionBlock;
LLVMBasicBlockRef loopBodyBlock; 
LLVMBasicBlockRef exitBlock; 
//Bloques para if  
LLVMBasicBlockRef ifBlock; 
LLVMBasicBlockRef elseBlock;
LLVMBasicBlockRef ifExitBlock; 


LLVMModuleRef createModule() {
    // Crear un módulo LLVM
    LLVMModuleRef module = LLVMModuleCreateWithName("miModulo");

    // Crear un tipo de función que devuelve un entero y no tiene parámetros
    LLVMTypeRef returnType = LLVMInt32TypeInContext(globalContext);
    LLVMTypeRef paramTypes[] = {};
    LLVMTypeRef functionType = LLVMFunctionType(returnType, paramTypes, 0, 0);

    // Crear la función en el módulo (puedes ajustar el nombre según tus necesidades)
    entryFunction = LLVMAddFunction(module, "main", functionType);

    // Crear un bloque básico en la función
    entryBlock = LLVMAppendBasicBlock(entryFunction, "entry");

    // Configurar el punto de inserción para las instrucciones
    globalBuilder = LLVMCreateBuilderInContext(globalContext);
    LLVMPositionBuilderAtEnd(globalBuilder, entryBlock);

    return module;
}

LLVMValueRef declareGlobalVariable(LLVMModuleRef module, LLVMTypeRef type, const char *name) {
    // Crear una variable global en el módulo
    LLVMValueRef globalVariable = LLVMAddGlobal(module, type, name);
    return globalVariable;
}

void generarAsignacion(const char *identificador, LLVMValueRef expresionValue) {
    // Buscar la variable en el módulo (suponiendo que ya se declaró)
    LLVMValueRef variable = LLVMGetNamedGlobal(module, identificador);

    // Verificar si la variable existe
    if (!variable) {
        fprintf(stderr, "Error: Variable %s no declarada\n", identificador);
        exit(EXIT_FAILURE);
    }

    // Generar código LLVM IR para la asignación
    LLVMBuildStore(globalBuilder, expresionValue, variable);
}


void generatePrintCode(const char *stringToPrint) {
    // Verificar si la función puts ya existe en el módulo
    LLVMValueRef putsFunction = LLVMGetNamedFunction(module, "puts");

    // Si no existe, agregar la función al módulo
    if (!putsFunction) {
        // Obtener el tipo de la función puts
        LLVMTypeRef putsParams[] = { LLVMPointerType(LLVMInt8Type(), 0) };
        LLVMTypeRef putsType = LLVMFunctionType(LLVMInt32Type(), putsParams, 1, 0);
        putsFunction = LLVMAddFunction(module, "puts", putsType);
    }

    // Crear un valor constante con la cadena a imprimir
    LLVMValueRef stringConstant = LLVMBuildGlobalStringPtr(globalBuilder, stringToPrint, "stringConstant");
    if (esCiclo == 1) {
        LLVMPositionBuilderAtEnd(globalBuilder, loopBodyBlock);
        LLVMBuildCall(globalBuilder, putsFunction, &stringConstant, 1, "");
    } else {
        LLVMBuildCall(globalBuilder, putsFunction, &stringConstant, 1, "");
    }
}

void generatePrintFCode(LLVMValueRef myVariable) {
    // Verificar si la función printf ya existe en el módulo
    LLVMValueRef printfFunction = LLVMGetNamedFunction(module, "printf");

    // Si no existe, agregar la función al módulo
    if (!printfFunction) {
    // Obtener el tipo de la función printf
    LLVMTypeRef printfParams[] = { LLVMPointerType(LLVMInt8Type(), 0) };
    LLVMTypeRef printfType = LLVMFunctionType(LLVMInt32Type(), printfParams, 1, 1);
    printfFunction = LLVMAddFunction(module, "printf", printfType);
    }

    // Crear un formato de cadena para imprimir el valor
    const char *formatString = "%s\n";

    // Crear un valor constante con el formato de cadena
    LLVMValueRef formatConstant = LLVMBuildGlobalStringPtr(globalBuilder, formatString, "formatString");
    // Cargar el valor de la variable global
    LLVMValueRef loadedValue = LLVMBuildLoad(globalBuilder, myVariable, "loadedValue");
    // Llamar a la función printf para imprimir el valor
    LLVMValueRef printfArgs[] = { formatConstant, loadedValue };
    LLVMBuildCall(globalBuilder, printfFunction, printfArgs, 2, "");
}

void generatePrintFCodeInt(LLVMValueRef myVariable) {
    // Verificar si la función printf ya existe en el módulo
    LLVMValueRef printfFunction = LLVMGetNamedFunction(module, "printf");

    // Si no existe, agregar la función al módulo
    if (!printfFunction) {
        // Obtener el tipo de la función printf
        LLVMTypeRef printfParams[] = { LLVMPointerType(LLVMInt8Type(), 0) };
        LLVMTypeRef printfType = LLVMFunctionType(LLVMInt32Type(), printfParams, 1, 1);
        printfFunction = LLVMAddFunction(module, "printf", printfType);
    }

    // Crear un formato de cadena para imprimir el valor entero
    const char *formatString = "El valor del entero es: %d\n";

    // Crear un valor constante con el formato de cadena
    LLVMValueRef formatConstant = LLVMBuildGlobalStringPtr(globalBuilder, formatString, "formatString");

    // Cargar el valor de la variable global
    LLVMValueRef loadedValue = LLVMBuildLoad(globalBuilder, myVariable, "loadedValue");

    // Llamar a la función printf para imprimir el valor
    LLVMValueRef printfArgs[] = { formatConstant, loadedValue };

    LLVMBuildCall(globalBuilder, printfFunction, printfArgs, 2, "");
}


// Estructura para una entrada de tabla de símbolos
typedef struct SymbolEntry {
    char* name;              // Nombre del identificador
    char* type;              // Tipo del identificador
    int scope;               // Ámbito del identificador
    struct SymbolEntry* entry;         // Entrada de símbolo
    struct SymbolEntry* next;  // Siguiente nodo en la lista enlazada
} SymbolEntry;

// Puntero al primer nodo de la tabla de símbolos
SymbolEntry* symbolTable = NULL;
struct TACList* head = NULL;  // Inicializa la lista vacía 



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
%token <cadena> IMPRESION 
%token INCREMENTO LECTURA ESCRITURA CICLO OP_LOGICO PREGUNTA_CONTRARIA PREGUNTA PORCT PAR_IZ PAR_DE COR_IZ COR_DE ASIGNACION
%left OP_ARITMETICO
%type <cadena> instruccion instrucciones declaracion parte_media bloque comparacion mientrasToken
%%

programa : instrucciones {   }
        ; 
preguntaIf : PREGUNTA  {
                ifBlock = LLVMAppendBasicBlock(entryFunction, "ifBlock");
                elseBlock = LLVMAppendBasicBlock(entryFunction, "elseBlock");
                ifExitBlock = LLVMAppendBasicBlock(entryFunction, "exitBlock");
                esIf = 1;
            }
            ;

cuerpoIf : preguntaIf comparacion bloque preguntaElse {
        LLVMPositionBuilderAtEnd(globalBuilder, entryBlock);
        // Saltar al bloque de condición 
        LLVMBuildCondBr(globalBuilder, globalCondition, ifBlock, elseBlock);

        LLVMPositionBuilderAtEnd(globalBuilder, ifBlock);
        LLVMBuildBr(globalBuilder, ifExitBlock);
        
        
        LLVMPositionBuilderAtEnd(globalBuilder, ifExitBlock);
        }
        ; 

preguntaElse : PREGUNTA_CONTRARIA {
                    esElse = 1;
                }
               | /* vacio */
               ;

elseCuerpo : preguntaElse bloque {
            LLVMPositionBuilderAtEnd(globalBuilder, elseBlock);
            LLVMBuildBr(globalBuilder, ifExitBlock);
}

comparacion : ID OP_RELACIONAL ID { if (existeTODO($1, $3) == 0) {
                                        
                                    }
                                    else {
                                    
                                        
                                    }
}
            | ID OP_RELACIONAL NUMERO { if (existeID ($1) == 0) {
                                        SymbolEntry* existingEntry = findInSymbolTable($1, symbolTable);
                                            if ( (strcmp(existingEntry->type, "float") == 0) || (strcmp(existingEntry->type, "double") == 0) || (strcmp(existingEntry->type, "int") == 0) ) {
                                                if (existingEntry->scope <= currentScope) { //Todo correcto
                                                    
                                                    
                                                    const char* constVariableName = $1;
                                                    // Buscar la variable en el módulo (suponiendo que ya se declaró)
                                                    LLVMValueRef variable = LLVMGetNamedGlobal(module, constVariableName);
                                                    if (variable == NULL) {
                                                        fprintf(stderr, "Error: Variable %s has not been declared.\n", $1);
                                                    } else {
                                                        if (esCiclo == 1) {
                                                            LLVMPositionBuilderAtEnd(globalBuilder, loopConditionBlock);
                                                        } 
                                                              
                                                        LLVMValueRef loadedValue = LLVMBuildLoad(globalBuilder, variable, "loadedValue");
                                                        LLVMValueRef leftExpr = loadedValue;
                                                        char* numeroStr = $3;
                                                        LLVMValueRef rightExpr = LLVMConstIntOfString(LLVMInt32TypeInContext(globalContext), numeroStr, 10);
                                                        // Dependiendo del operador, realiza la comparación
                                                        if (strcmp($2, "==") == 0) {                                       
                                                            globalCondition = LLVMBuildICmp(globalBuilder, LLVMIntEQ, leftExpr, rightExpr, "cmpResult"); 
                                                        } else if (strcmp($2, "<") == 0) {
                                                            globalCondition = LLVMBuildICmp(globalBuilder, LLVMIntULT, leftExpr, rightExpr, "cmpResult"); 
                                                        } else if (strcmp($2, "<=") == 0) {
                                                            globalCondition = LLVMBuildICmp(globalBuilder, LLVMIntULE, leftExpr, rightExpr, "cmpResult"); 
                                                        } else if (strcmp($2, ">") == 0) {
                                                            globalCondition = LLVMBuildICmp(globalBuilder, LLVMIntUGT, leftExpr, rightExpr, "cmpResult"); 
                                                        } else if (strcmp($2, ">=") == 0) {
                                                            globalCondition = LLVMBuildICmp(globalBuilder, LLVMIntUGE, leftExpr, rightExpr, "cmpResult"); 
                                                        } 
                                                    }  
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

escritura : ESCRITURA ID {}
        ; 
impresion : IMPRESION OP_ARITMETICO ID OP_ARITMETICO {
            const char* constVariableName = $3;
            // Buscar la variable en el módulo (suponiendo que ya se declaró)
            LLVMValueRef variable = LLVMGetNamedGlobal(module, constVariableName);
            if (variable != NULL) {
                SymbolEntry* existingEntry = findInSymbolTable($3, symbolTable);
                if ((strcmp(existingEntry->type, "int") == 0)) {
                    if (esCiclo == 1) {
                        LLVMPositionBuilderAtEnd(globalBuilder, loopBodyBlock); 
                        generatePrintFCodeInt(variable);      
                    } else if (esIf == 1) {
                        LLVMPositionBuilderAtEnd(globalBuilder, ifBlock);
                        generatePrintFCodeInt(variable);           
                    } else if (esElse == 1) {
                        LLVMPositionBuilderAtEnd(globalBuilder, elseBlock);
                        generatePrintFCodeInt(variable);           
                    } else {
                        generatePrintFCodeInt(variable);           
                    }
                } else if ((strcmp(existingEntry->type, "string") == 0)) {
                    if (esCiclo == 1) {
                        LLVMPositionBuilderAtEnd(globalBuilder, loopBodyBlock); 
                        generatePrintFCode(variable);      
                    } else if (esIf == 1) {
                        LLVMPositionBuilderAtEnd(globalBuilder, ifBlock); 
                        generatePrintFCode(variable);           
                    } else if (esElse == 1) {
                        LLVMPositionBuilderAtEnd(globalBuilder, elseBlock);
                        generatePrintFCode(variable);           
                    } else {
                        generatePrintFCode(variable);           
                    }
                }
                
            } else {
                if (esCiclo == 1) {
                        LLVMPositionBuilderAtEnd(globalBuilder, loopBodyBlock); 
                        generatePrintCode($3);      
                    } else if (esIf == 1) {
                        LLVMPositionBuilderAtEnd(globalBuilder, ifBlock); 
                        generatePrintCode($3);           
                    } else if (esElse == 1) {
                        LLVMPositionBuilderAtEnd(globalBuilder, elseBlock);
                        generatePrintCode($3);           
                    } else {
                        generatePrintCode($3);           
                    }
            }            
}   
        ;

mientrasToken : CICLO {
        loopConditionBlock = LLVMAppendBasicBlock(entryFunction, "loopCondition");
        loopBodyBlock = LLVMAppendBasicBlock(entryFunction, "loopBody");
        exitBlock = LLVMAppendBasicBlock(entryFunction, "exit");
        esCiclo = 1; 
        creoLoop = 1;
    } 
    ; 

mientras : mientrasToken comparacion bloque { 
        LLVMPositionBuilderAtEnd(globalBuilder, entryBlock);
        // Saltar al bloque de condición del bucle
        LLVMBuildBr(globalBuilder, loopConditionBlock);

        // Bloque de condición del bucle
        LLVMPositionBuilderAtEnd(globalBuilder, loopConditionBlock);
        LLVMBuildCondBr(globalBuilder, globalCondition, loopBodyBlock, exitBlock);
        // Salto de regreso al bloque de condición del bucle
        LLVMPositionBuilderAtEnd(globalBuilder, loopBodyBlock);
        LLVMBuildBr(globalBuilder, loopConditionBlock);

        // Bloque de salida del bucle
        LLVMPositionBuilderAtEnd(globalBuilder, exitBlock);
        
        // Código semántico si es necesario
        esCiclo = 0; // Restablecer la bandera
    }
        ; 


declaracion : TIPODATO ID { addToSymbolTable($2, $1); 
                            if (strcmp($1, "int") == 0) {
                                // Instrucción: Declaración de variable
                                LLVMTypeRef intType = LLVMInt32TypeInContext(globalContext);
                                LLVMValueRef myGlobalVariable = declareGlobalVariable(module, intType, $2);
                            } else if (strcmp($1, "boolean") == 0) {
                                LLVMTypeRef booleanType = LLVMInt1TypeInContext(globalContext);
                                LLVMValueRef myGlobalVariable = declareGlobalVariable(module, booleanType, $2);
                            } else if (strcmp($1, "string") == 0) {
                                LLVMTypeRef stringType = LLVMPointerType(LLVMInt8TypeInContext(globalContext), 0);
                                LLVMValueRef myGlobalVariable = declareGlobalVariable(module, stringType, $2);
                            }
                           
                            
                        }
        ; 

bloque : parte_iz parte_media parte_der {        
        }
        ; 

parte_iz : COR_IZ {openScope();
}
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
                    esIf = 0; 
                    esElse = 0;
                    }
        ; 

asignacion : ID ASIGNACION ID {   SymbolEntry* existingEntry = findInSymbolTable($3, symbolTable); 
                                    if (existingEntry ==  NULL) { //Es cadena
                                        if (existeID ($1) == 0) {
                                            SymbolEntry* existingEntry = findInSymbolTable($1, symbolTable);
                                            if ( (strcmp(existingEntry->type, "string") == 0)  ) { //Cadena con cadena
                                                const char* constVariableName = $1;
                                                // Buscar la variable en el módulo (suponiendo que ya se declaró)
                                                LLVMValueRef variable = LLVMGetNamedGlobal(module, constVariableName);
                                                if (variable == NULL) {
                                                    fprintf(stderr, "Error: Variable %s has not been declared.\n", $1);
                                                } else {
                                                    char* cadena = $3;
                                                    // Crear un valor constante que representa la cadena
                                                    LLVMTypeRef stringType = LLVMPointerType(LLVMInt8TypeInContext(globalContext), 0);
                                                    LLVMValueRef expresionValue = LLVMBuildGlobalStringPtr(globalBuilder, cadena, "stringConstant");
                                                    LLVMSetInitializer(variable, LLVMConstNull(stringType));
                                                    LLVMSetLinkage(variable, LLVMExternalLinkage);
                                                    // Llamar a la función para asignar el valor a la variable global
                                                    LLVMBuildStore(globalBuilder, expresionValue, variable);
                                                    
                                                }

                                            }
                                            else {
                                                fprintf(stderr, "Error de compilacion: variable %s tipos incompatibles\n", $1);
                                                error_counter++;
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
                                            const char* constVariableName = $1;
                                                LLVMValueRef variable = LLVMGetNamedGlobal(module, constVariableName);
                                                if (variable == NULL) {
                                                    fprintf(stderr, "Error: Variable %s has not been declared.\n", $1);
                                                } else {
                                                    int intValue = atoi($3); // Convierte el número en cadena a un entero
                                                    
                                                    // Crear un valor constante que representa el entero
                                                    LLVMTypeRef intType = LLVMInt32TypeInContext(globalContext);
                                                    LLVMValueRef intValueConstant = LLVMConstInt(intType, intValue, 0);

                                                    // Asignar el valor a la variable global
                                                    LLVMSetInitializer(variable, intValueConstant);
                                                    LLVMSetLinkage(variable, LLVMExternalLinkage);
                                                }

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


incremento : ID INCREMENTO { 
                            const char* constVariableName = $1;
                            LLVMValueRef variable = LLVMGetNamedGlobal(module, constVariableName);
                            if (variable == NULL) {
                                fprintf(stderr, "Error: Variable %s has not been declared.\n", $1);
                            } else { 
                                if (esCiclo == 1) {
                                    LLVMPositionBuilderAtEnd(globalBuilder, loopBodyBlock);
                                    // Cargar el valor actual de la variable
                                    LLVMValueRef currentValue = LLVMBuildLoad(globalBuilder, variable, "currentValue");
                                    // Incrementar el valor
                                    LLVMValueRef incrementedValue = LLVMBuildAdd(globalBuilder, currentValue, LLVMConstInt(LLVMInt32Type(), 1, false), "incrementedValue");
                                    // Almacenar el valor incrementado en la variable
                                    LLVMBuildStore(globalBuilder, incrementedValue, variable);
                                } else {
                                    // Cargar el valor actual de la variable
                                    LLVMValueRef currentValue = LLVMBuildLoad(globalBuilder, variable, "currentValue");
                                    // Incrementar el valor
                                    LLVMValueRef incrementedValue = LLVMBuildAdd(globalBuilder, currentValue, LLVMConstInt(LLVMInt32Type(), 1, false), "incrementedValue");
                                    // Almacenar el valor incrementado en la variable
                                    LLVMBuildStore(globalBuilder, incrementedValue, variable);
                                    
                                }
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
        | mientras
        | cuerpoIf
        | elseCuerpo
        | escritura 
        | impresion
        | incremento
        ; 

%%

int main() {
    // Abrir el archivo de entrada
    FILE* inputFile = fopen("Datos.txt", "r");
    if (!inputFile) {
        perror("Error al abrir el archivo de entrada");
        return 1;
    }

    // Abrir el archivo de salida para escribir
    FILE* outputFile = fopen("intermedio.txt", "w");
    if (!outputFile) {
        perror("Error al abrir el archivo de salida");
        fclose(inputFile);  // Cerrar el archivo de entrada antes de salir
        return 1;
    }

    // Configurar el analizador léxico para leer desde el archivo de entrada
    yyin = inputFile;

    // Crear el contexto LLVM (global)
    globalContext = LLVMGetGlobalContext();
    // Crear el módulo
    module = createModule();
    // Analizar el código fuente
    yyparse();
    
    // Verificar si hubo errores durante el análisis
    if (error_counter == 0) {
        printf("\nCompilacion exitosa :).\n");
        // Agregar la instrucción ret al final del bloque
        LLVMPositionBuilderAtEnd(globalBuilder, entryBlock);
        LLVMTypeRef returnType = LLVMInt32TypeInContext(globalContext);
        LLVMBuildRet(globalBuilder, LLVMConstInt(returnType, 0, 0));
        // Agregar la instrucción ret al final del bloque ciclo
        LLVMPositionBuilderAtEnd(globalBuilder, exitBlock);
        LLVMBuildRet(globalBuilder, LLVMConstInt(returnType, 0, 0));
        // Agregar la instrucción ret al final del bloque if
        LLVMPositionBuilderAtEnd(globalBuilder, ifExitBlock);
        if (creoLoop == 1) {
            LLVMBuildBr(globalBuilder, loopConditionBlock);
        } else {
            LLVMBuildRet(globalBuilder, LLVMConstInt(returnType, 0, 0));
        }
        // Especificar el target triple
        LLVMSetTarget(module, "x86_64-pc-linux-gnu");
        // Agregar la instrucción ret al final del bloque  
        // Redirigir la salida estándar al archivo "salida.ll"
        freopen("salida.ll", "w", stdout);

        // Imprimir el IR generado en el archivo
        char *irCode = LLVMPrintModuleToString(module);
        printf("%s\n", irCode);
        LLVMDisposeMessage(irCode);
    }

    // Cerrar archivos antes de salir
    fclose(inputFile);
    fclose(outputFile);

    return 0;
}



void yyerror(const char *msg) {
    fprintf(stderr, "Error encontrado: %s. Token: %s\n", msg, yytext);
    error_counter++;
}
