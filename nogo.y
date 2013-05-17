%{

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

extern int    yylineno; /* numero de linea, gestionado por flex */
extern char * yytext;   /* texto reconocido por flex            */

int count_errors = 0;   /* contador de errores */

int  yylex   (void);
void yyerror (char * s);

%}

 /* terminales:
  * el token "ERROR" nunca es usado en el parser, por lo tanto se considerara
  * un error sintactico siempre que sea retornado por flex
  */
%token AND ARRAY ASSIGN BEGIN_ BOOLEAN BOOLEAN_T CASE CHARACTER CHARACTER_T
%token CONSTANT DISTINCT ELSE END ERROR EXIT EXPONENT FOR FOREACH FUNCTION
%token GREAT_EQ HASHTABLE IDENTIFIER IF IN INTEGER INTEGER_T IS LESS_EQ LOOP
%token MOD NOT NULL_ OF OR OTHERS OUT PROCEDURE RANGE RARROW REAL REAL_T RECORD
%token RETURN REVERSE STRING THEN TYPE WHEN WHILE

 /* reglas de precedencia: solucionan la ambigüedad array/funcion, otorgandole
  * mayores "privilegios" a la llamadas a funciones, así "foo(bar)" será
  * reconocido siempre como una llamada a función, y nunca el acceso a un
  * array: 
  */
/* %nonassoc IDENTIFIER */
/* %nonassoc '(' */

%%

program_list
    : /* cadena vacia */
    | program program_list
    | error program_list
    ;

program
    : PROCEDURE IDENTIFIER IS
        declaration_list
        BEGIN_
            instruction_list
        END IDENTIFIER ';'
    ;

declaration_list
    : /* cadena vacia */
    | declaration declaration_list
    | error declaration_list
    ;

declaration
    : object_declaration
    | type_declaration
    | subprogram_declaration
    ;

object_declaration
    : id_list ':' CONSTANT scalar_type ASSIGN expression ';'
    | id_list ':' scalar_type ASSIGN expression ';'
    | id_list ':' scalar_type ';'
    | id_list ':' complex_type ';'
    | id_list ':' type_name ';'
    ;

id_list
    : IDENTIFIER
    | IDENTIFIER ',' id_list
    ;

type_declaration
    : TYPE type_name IS complex_type ';'
    ;

type_name
    : IDENTIFIER
    ;

scalar_type
    : INTEGER_T
    | REAL_T
    | BOOLEAN_T
    | CHARACTER_T
    ;

complex_type
    : array_type
    | record_type
    | hashtable_type
    ;

array_type
    : ARRAY '(' expression RANGE expression ')' OF type_spec
    ;

record_type
    : RECORD component_list END RECORD
    ;

component_list
    : component
    | component component_list
    ;

component
    : id_list ':' type_spec ';'
    ;

type_spec
    : complex_type
    | scalar_type
    | type_name
    ;

hashtable_type
    : HASHTABLE OF '<' type_spec ',' type_spec '>'
    ;

name
    : IDENTIFIER
    | indexed_component
    | selected_component
    | function_call
    ;

indexed_component
    : name '(' expression ')'
    /* posible solucion alternativa a las precedencias en el problema de acceso
     * a array y llamada a funcion, modificacion de la sintaxis para acceso a
     * un array, utilizando corchetes en lugar de parentesis (requiere
     * modificacion tambien en Flex para que reconozca los corchetes como
     * simbolos validos, ya incluida en el fichero nogo.l)
     */
    /* : name '[' expression ']' */
    | name '{' expression '}'
    ;

selected_component
    : name '.' IDENTIFIER
    ;

literal
    : INTEGER
    | REAL
    | BOOLEAN
    | CHARACTER
    | STRING
    ;

expression
    : relation
    | relation logical_oper expression
    ;

relation
    : simple_expression
    | simple_expression relational_oper simple_expression
    ;

simple_expression
    : term_list
    | unary_oper term_list
    ;

term_list
    : term
    | term addition_oper term_list
    ;

term
    : factor_list
    ;

factor_list
    : factor
    | factor multiplication_oper factor_list
    ;

factor
    : primary
    | primary EXPONENT primary
    ;

primary
    : literal
    | name
    | '(' expression ')'
    ;

logical_oper
    : AND
    | OR
    ;

relational_oper
    : '='
    | DISTINCT
    | '<'
    | LESS_EQ
    | '>'
    | GREAT_EQ
    ;

addition_oper
    : '+'
    | '-'
    ;

unary_oper
    : '+'
    | '-'
    | NOT
    ;

multiplication_oper
    : '*'
    | '/'
    | MOD
    ;

instruction_list
    : /* cadena vacia */
    | instruction instruction_list
    | error instruction_list
    ;

instruction
    : simple_instruction
    | complex_instruction
    ;

simple_instruction
    : empty_instruction
    | assign_instruction
    | exit_instruction
    | return_instruction
    | procedure_call
    ;

complex_instruction
    : if_instruction
    | case_instruction
    | loop_instruction
    ;

empty_instruction
    : NULL_
    ;

assign_instruction
    : name ASSIGN expression ';'
    ;

if_instruction
    : IF expression THEN instruction_list END IF ';'
    | IF expression THEN instruction_list ELSE instruction_list END IF ';'
    ;

case_instruction
    : CASE expression IS when_list END CASE ';'
    ;

when_list
    : /* cadena vacia */
    | WHEN entry_list RARROW instruction_list when_list
    ;

entry_list
    : entry
    | entry '|' entry_list
    ;

entry
    : expression
    | expression RANGE expression
    | OTHERS
    ;

loop_instruction
    : IDENTIFIER ':' iteration_clause base_loop IDENTIFIER ';'
    | IDENTIFIER ':' base_loop IDENTIFIER ';'
    | iteration_clause base_loop ';'
    | base_loop ';'
    ;

iteration_clause
    : FOR IDENTIFIER IN REVERSE expression RANGE expression
    | FOR IDENTIFIER IN expression RANGE expression
    | FOREACH IDENTIFIER IN IDENTIFIER
    | WHILE expression
    ;

base_loop
    : LOOP instruction_list END LOOP
    ;

return_instruction
    : RETURN expression ';'
    ;

exit_instruction
    : EXIT IDENTIFIER WHEN expression ';'
    | EXIT WHEN expression ';'
    | EXIT IDENTIFIER ';'
    | EXIT ';'
    ;

subprogram_declaration
    : subprogram_specs ';'
    | subprogram_specs subprogram_body
    ;

subprogram_specs
    : PROCEDURE IDENTIFIER '(' formal_params ')'
    | PROCEDURE IDENTIFIER
    | FUNCTION IDENTIFIER '(' formal_params ')' RETURN type_spec
    | FUNCTION IDENTIFIER RETURN type_spec
    ;

formal_params
    : /* cadena vacia */
    | declare_params_list
    ;

declare_params_list
    : declare_params
    | declare_params ';' declare_params_list
    ;

declare_params
    : id_list ':' mode type_spec
    ;

mode : /* cadena vacia */
     | IN
     | IN OUT
     ;

subprogram_body
    : IS declaration_list BEGIN_ instruction_list END IDENTIFIER ';'
    | IS declaration_list BEGIN_ instruction_list END ';'
    ;

procedure_call
    : IDENTIFIER ';'
    | IDENTIFIER '(' actual_params_list ')' ';'
    ;

function_call
    : IDENTIFIER '(' ')'
    | IDENTIFIER '(' actual_params_list ')'
    ;

actual_params_list
    : expression
    | expression ',' actual_params_list
    ;

%%

/* funcion llamada en cada error de parseo encontrado */
void yyerror (char * error_msg)
{
    fprintf(stderr, "ERROR: %s [%s], linea %d\n", error_msg, yytext, yylineno);

    count_errors++;
    if (count_errors == 50) {
        fprintf(stderr, "Alcanzados 50 errores, abortando analisis.\n");
        printf("Programa NOGO incorrecto: %d errores encontrados.\n", count_errors);
        exit(1);
    }
}

/* main, entrada para el analizador sintactico */
int main (int argc, char * argv[ ])
{
    extern FILE * yyin;

    if (argc != 2) {
        fprintf(stderr, "USO: %s fichero\n", argv[0]);
        return -1;
    }

    yyin = fopen(argv[1], "r");
    if (!yyin) {
        fprintf(stderr, "No existe el fichero %s\n", argv[1]);
        return -1;
    }

    yyparse();
    fclose(yyin);

    if (count_errors == 0) {
        printf("Programa NOGO correcto.\n");
        return 0;
    } else {
        printf("Programa NOGO incorrecto: %d %s.\n", count_errors,
               count_errors > 1 ? "errores encontrados" : "error encontrado");
        return 1;
    }
}

