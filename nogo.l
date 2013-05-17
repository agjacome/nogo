%{

#include <ctype.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "nogo.tab.h"

/* Longitud maxima para cadena de caracteres literal */
#define MAX_STR_LEN             4096

/* buffer para almacenamiento de cadenas literales, junto a su longitud */
int  string_len = 0;
char string_buffer[MAX_STR_LEN];

/* variable para almacenamiento de caracter encontrado */
char char_buff;

/* flags de errores */
bool string_err      = false;
bool string_long_err = false;
bool char_found      = false;
bool char_error      = false;

/* funciones auxiliares (definidas al final del fichero) */
void string_buffer_add (char c);

%}

 /* cuenta numeros de linea en la variable yylineno */
%option yylineno

 /* Basico */
DIGIT           [0-9]
ALPHA           [a-zA-Z]
ALPHANUM_       [a-zA-Z0-9_]

 /* Identificadores */
IDENTIFIER      {ALPHA}{ALPHANUM_}*

 /* Tipos de datos */
INTEGER_T       (?i:integer)
REAL_T          (?i:real)
BOOLEAN_T       (?i:boolean)
CHARACTER_T     (?i:character)

 /* Literales numericos */
INTEGER         {DIGIT}+
REAL            {DIGIT}+\.{DIGIT}+(e|E(\+|\-)?{DIGIT}+)?

 /* Literales booleanos */
TRUE            (?i:true)
FALSE           (?i:false)

 /* Operadores, delimitadores y puntuacion */
OPERATOR        [\+\-\*\/\<\>\=\|]
PUNCTUATION     [\(\)\{\}\,\.\;\:\[\]]

 /* Operadores multi-caracter */
RARROW          \=\>
ASSIGN          \:\=
DISTINCT        \/\=
LESS_EQ         \<\=
GREAT_EQ        \>\=
EXPONENT        \*\*
RANGE           \.\.
AND             (?i:and)
OR              (?i:or)
NOT             (?i:not)
MOD             (?i:mod)

 /* Comentarios */
COMMENTARY      \-\-.*

 /* Palabras reservadas */
ARRAY           (?i:array)
BEGIN           (?i:begin)
CASE            (?i:case)
CONSTANT        (?i:constant)
ELSE            (?i:else)
END             (?i:end)
EXIT            (?i:exit)
FOR             (?i:for)
FOREACH         (?i:foreach)
FUNCTION        (?i:function)
HASHTABLE       (?i:hashtable)
IF              (?i:if)
IN              (?i:in)
IS              (?i:is)
LOOP            (?i:loop)
NULL            (?i:null)
OF              (?i:of)
OTHERS          (?i:others)
OUT             (?i:out)
PROCEDURE       (?i:procedure)
RECORD          (?i:record)
RETURN          (?i:return)
REVERSE         (?i:reverse)
THEN            (?i:then)
TYPE            (?i:type)
WHEN            (?i:when)
WHILE           (?i:while)

 /* Espacios en blanco */
WHITESPACE      [ \f\r\t\v]
NEWLINE         \n

 /* Condiciones de arranque */
%x STRING
%x CHARACTER

%%

 /* Comentarios: se ignoran */
{COMMENTARY}        { }

 /* Operadores y delimitadores */
{RARROW}            return RARROW;
{ASSIGN}            return ASSIGN;
{DISTINCT}          return DISTINCT;
{LESS_EQ}           return LESS_EQ;
{GREAT_EQ}          return GREAT_EQ;
{EXPONENT}          return EXPONENT;
{RANGE}             return RANGE;
{AND}               return AND;
{OR}                return OR;
{NOT}               return NOT;
{MOD}               return MOD;
{OPERATOR}          return yytext[0];
{PUNCTUATION}       return yytext[0];

 /* Palabras reservadas */
{ARRAY}             return ARRAY;
{BEGIN}             return BEGIN_;
{CASE}              return CASE;
{CONSTANT}          return CONSTANT;
{ELSE}              return ELSE;
{END}               return END;
{EXIT}              return EXIT;
{FOR}               return FOR;
{FOREACH}           return FOREACH;
{FUNCTION}          return FUNCTION;
{HASHTABLE}         return HASHTABLE;
{IF}                return IF;
{IN}                return IN;
{IS}                return IS;
{LOOP}              return LOOP;
{NULL}              return NULL_;
{OF}                return OF;
{OTHERS}            return OTHERS;
{OUT}               return OUT;
{PROCEDURE}         return PROCEDURE;
{RECORD}            return RECORD;
{RETURN}            return RETURN;
{REVERSE}           return REVERSE;
{THEN}              return THEN;
{TYPE}              return TYPE;
{WHEN}              return WHEN;
{WHILE}             return WHILE;

 /* Nombres de tipo */
{INTEGER_T}         return INTEGER_T;
{REAL_T}            return REAL_T;
{BOOLEAN_T}         return BOOLEAN_T;
{CHARACTER_T}       return CHARACTER_T;

 /* Literales */
{TRUE}              return BOOLEAN;
{FALSE}             return BOOLEAN;
{INTEGER}           return INTEGER;
{REAL}              return REAL;   

 /* Identificadores */
{IDENTIFIER}        return IDENTIFIER;

 /* Caracteres */
\' {
    BEGIN(CHARACTER);
    char_buff  = '\0';
    char_found = false;
    char_error = false;
}
<CHARACTER>\' {
    BEGIN(INITIAL);
    return CHARACTER;
}
<CHARACTER><<EOF>> {
    BEGIN(INITIAL);
    return ERROR;
}
<CHARACTER>{NEWLINE} {
    char_error = true;
}
<CHARACTER>\0 {
    char_error = true;
}
<CHARACTER>\\[btnf] {
    if (char_found && !char_error) {
        char_error = true;
    } else if (!char_error) {
        switch (yytext[1]) {
            case 'b': char_buff = '\b'; break;
            case 't': char_buff = '\t'; break;
            case 'n': char_buff = '\n'; break;
            case 'f': char_buff = '\f'; break;
        }
        char_found = true;
    }
}
<CHARACTER>\\\' {
    if (char_found && !char_error) {
        char_error = true;
    } else if (!char_error) {
        char_buff = yytext[1];
        char_found = true;
    }
}
<CHARACTER>\\. {
    if (char_found && !char_error) {
        char_error = true;
    } else if (!char_error) {
        char_buff  = yytext[1];
        char_found = true;
    }
}
<CHARACTER>[^\'\\\0\{NEWLINE}] {
    if (char_found && !char_error) {
        char_error = true;
    } else if (!char_error) {
        char_buff  = yytext[0];
        char_found = true;
    }
}

 /* Cadenas de caracteres */
\" {
    BEGIN(STRING);
    string_len      = 0;
    string_err      = false;
    string_long_err = false;
}
<STRING>\" {
    BEGIN(INITIAL);
    if (string_long_err) {
        return ERROR;
    } else if (!string_err) {
        string_buffer_add('\0');
        return STRING;
    }
}
<STRING><<EOF>> {
    BEGIN(INITIAL);
    return ERROR;
}
<STRING>{NEWLINE} {
    string_err = true;
}
<STRING>\0 {
    string_err = true;
}
<STRING>\\{NEWLINE} {
    string_buffer_add('\n');
}
<STRING>\\[btnf] {
    switch (yytext[1]) {
        case 'b': string_buffer_add('\b'); break;
        case 't': string_buffer_add('\t'); break;
        case 'n': string_buffer_add('\n'); break;
        case 'f': string_buffer_add('\f'); break;
    }
}
<STRING>\\\"        string_buffer_add('"');
<STRING>\\.         string_buffer_add(yytext[1]);
<STRING>.           string_buffer_add(yytext[0]);

 /* Saltos de linea y espacios en blanco */
{NEWLINE}       { }
{WHITESPACE}+   { }

 /* Cualquier otro caracter es un error */
.                   return ERROR;

%%

/* string_buffer_add:
 * añade el caracter c al buffer de cadenas de caracteres, comprobando que no
 * se supera la longitud maxima posible (MAX_STR_LEN) y poninedo a verdadero el
 * flag string_long_err si asi sucede.
 */
void string_buffer_add (char c)
{
    if (string_long_err)
        return;

    string_buffer[string_len++] = c;

    if (string_len == MAX_STR_LEN - 1)
        string_long_err = true;
}

