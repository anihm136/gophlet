%{
#include "common.h"
#include "go_parser.tab.h"
%}

%option yylineno
/* Characters */
letter        [a-zA-Z]|_
decimal_digit [0-9]
newline        "\n"
whitespace     [[:space:]]+

/* To be changed */
unicode_char   .
unicode_letter {letter}
unicode_digit  {decimal_digit}

/* Digits */
decimal_digits {decimal_digit}(_?{decimal_digit})*
binary_digit   0|1
binary_digits  {binary_digit}(_?{binary_digit})*
octal_digit    [0-7]
octal_digits   {octal_digit}(_?{octal_digit})*
hex_digit      [0-9]|[A-F]|[a-f]
hex_digits     {hex_digit}(_?{hex_digit})*

/* Identifier */
identifier {letter}({letter}|{unicode_digit})*

/* Operators and punctuations */
operator_addeq "+="
operator_andeq "&="
operator_land "&&"
operator_eq "=="
operator_lneq "!="
operator_subeq "-="
operator_oreq "|="
operator_lor "||"
operator_lt "<"
operator_leq "<="
operator_muleq "*="
operator_xoreq "^="
operator_chan_dir "<-"
operator_gt ">"
operator_geq ">="
operator_lshift "<<"
operator_diveq "/="
operator_lshifteq "<<="
operator_inc "++"
operator_assgn ":="
operator_rshift ">>"
operator_modeq "%="
operator_rshifteq ">>="
operator_dec "--"
operator_ellipses "..."
operator_ampxor "&^"
operator_ampxoreq "&^="
operator_char "+"|"&"|"("|")"|"-"|"|"|"["|"]"|"^"|":"|"."|"{"|"}"|"/"|"*"|"="|","|";"|"%"|"!"

/* Integer literals */
int_lit     {decimal_lit}|{binary_lit}|{octal_lit}|{hex_lit}
decimal_lit 0|([1-9](_?{decimal_digits})?)
binary_lit  0[bB]_?{binary_digits}
octal_lit   0[oO]_?{octal_digits}
hex_lit     0[xX]_?{hex_digits}

/* Float literals */
float_lit         {decimal_float_lit}|{hex_float_lit}
decimal_float_lit ({decimal_digits}"."{decimal_digits}?{decimal_exponent}?)|{decimal_digits}{decimal_exponent}
decimal_exponent  [eE][+-]?{decimal_digits}
hex_float_lit     0[xX]{hex_mantissa}{hex_exponent}
hex_mantissa      (_?{hex_digits}"."{hex_digits}?)|(_?{hex_digits})|("."{hex_digits})
hex_exponent      [pP][+-]?{decimal_digits}

/* Imaginary literals */
imaginary_lit ({decimal_digits}|{int_lit}|{float_lit})i

/* Rune literals */
rune_lit         \'({unicode_value}|{byte_value})\'
unicode_value    {unicode_char}|{little_u_value}|{big_u_value}|escaped_char
byte_value       {octal_byte_value}|{hex_byte_value}
octal_byte_value \\{octal_digit}{3}
hex_byte_value   \\x{hex_digit}{2}
little_u_value   \\u{hex_digit}{4}
big_u_value      \\u{hex_digit}{8}
escaped_char     \\[abfnrtv\\\'\"]

/* String literals */
string_lit             {raw_string_lit}|{interpreted_string_lit}
unicode_char_noquote   [^\"]
unicode_char_notick    [^\`]
unicode_value_noquote  {unicode_char_noquote}|{little_u_value}|{big_u_value}|escaped_char
raw_string_lit         \`({unicode_char_notick}|{newline})*\`
interpreted_string_lit \"({unicode_value_noquote}|{byte_value})*\"

/* Keywords */
keyword_break       break
keyword_default     default
keyword_func        func
keyword_interface   interface
keyword_select      select
keyword_case        case
keyword_defer       defer
keyword_go          go
keyword_map         map
keyword_struct      struct
keyword_chan        chan
keyword_else        else
keyword_goto        goto
keyword_package     package
keyword_switch      switch
keyword_const       const
keyword_fallthrough fallthrough
keyword_if          if
keyword_range       range
keyword_type        type
keyword_continue    continue
keyword_for         for
keyword_import      import
keyword_return      return
keyword_var         var

/* Predeclared types */
predeclared_type bool|byte|complex64|complex128|error|float32|float64|int|int8|int16|int32|int64|rune|string|uint|uint8|uint16|uint32|uint64|uintptr

/* Predeclared constants */
predeclared_const true|false
/* |iota */

/* Zero value */
predeclared_zero nil

/* Predeclared functions */
predeclared_functions append|cap|close|complex|copy|delete|imag|len|make|new|panic|print|println|real|recover
/* Comments */
comment       {line_comment}|{block_comment}
line_comment  "//".*
block_comment "/*"[^*]*"*"+([^*/][^*]*"*"+)*"/" 

%%

{whitespace} ;
{comment} ;
{operator_char}     {*((char*)&yylval) = yytext[0]; return yytext[0];}
{operator_addeq}    {yylval.O_ADDEQ = strdup(yytext); return O_ADDEQ;}
{operator_andeq}    {yylval.O_ANDEQ = strdup(yytext); return O_ANDEQ;}
{operator_land}     {yylval.O_LAND = strdup(yytext); return O_LAND;}
{operator_eq}       {yylval.O_EQ = strdup(yytext); return O_EQ;}
{operator_lneq}     {yylval.O_NEQ = strdup(yytext); return O_NEQ;}
{operator_subeq}    {yylval.O_SUBEQ = strdup(yytext); return O_SUBEQ;}
{operator_oreq}     {yylval.O_OREQ = strdup(yytext); return O_OREQ;}
{operator_lor}      {yylval.O_LOR = strdup(yytext); return O_LOR;}
{operator_lt}       {yylval.O_LT = strdup(yytext); return O_LT;}
{operator_leq}      {yylval.O_LEQ = strdup(yytext); return O_LEQ;}
{operator_muleq}    {yylval.O_MULEQ = strdup(yytext); return O_MULEQ;}
{operator_xoreq}    {yylval.O_XOREQ = strdup(yytext); return O_XOREQ;}
{operator_chan_dir} {yylval.O_CHAN_DIR = strdup(yytext); return O_CHAN_DIR;}
{operator_gt}       {yylval.O_GT = strdup(yytext); return O_GT;}
{operator_geq}      {yylval.O_GEQ = strdup(yytext); return O_GEQ;}
{operator_lshift}   {yylval.O_LSHIFT = strdup(yytext); return O_LSHIFT;}
{operator_diveq}    {yylval.O_DIVEQ = strdup(yytext); return O_DIVEQ;}
{operator_lshifteq} {yylval.O_LSHIFTEQ = strdup(yytext); return O_LSHIFTEQ;}
{operator_inc}      {yylval.O_INC = strdup(yytext); return O_INC;}
{operator_assgn}    {yylval.O_ASSGN = strdup(yytext); return O_ASSGN;}
{operator_rshift}   {yylval.O_RSHIFT = strdup(yytext); return O_RSHIFT;}
{operator_modeq}    {yylval.O_MODEQ = strdup(yytext); return O_MODEQ;}
{operator_rshifteq} {yylval.O_RSHIFTEQ = strdup(yytext); return O_RSHIFTEQ;}
{operator_dec}      {yylval.O_DEC = strdup(yytext); return O_DEC;}
{operator_ellipses} {yylval.O_ELLIPSES = strdup(yytext); return O_ELLIPSES;}
{operator_ampxor}   {yylval.O_AMPXOR = strdup(yytext); return O_AMPXOR;}
{operator_ampxoreq} {yylval.O_AMPXOREQ = strdup(yytext); return O_AMPXOREQ;}
{keyword_break} {return K_BREAK;}
{keyword_default} {return K_DEFAULT;}
{keyword_func} {return K_FUNC;}
{keyword_interface} {return K_INTERFACE;}
{keyword_select} {return K_SELECT;}
{keyword_case} {return K_CASE;}
{keyword_defer} {return K_DEFER;}
{keyword_go} {return K_GO;}
{keyword_map} {return K_MAP;}
{keyword_struct} {return K_STRUCT;}
{keyword_chan} {return K_CHAN;}
{keyword_else} {return K_ELSE;}
{keyword_goto} {return K_GOTO;}
{keyword_package} {return K_PACKAGE;}
{keyword_switch} {return K_SWITCH;}
{keyword_const} {return K_CONST;}
{keyword_fallthrough} {return K_FALLTHROUGH;}
{keyword_if} {return K_IF;}
{keyword_range} {return K_RANGE;}
{keyword_type} {return K_TYPE;}
{keyword_continue} {return K_CONTINUE;}
{keyword_for} {return K_FOR;}
{keyword_import} {return K_IMPORT;}
{keyword_return} {return K_RETURN;}
{keyword_var} {return K_VAR;}
{predeclared_type} return P_TYPE;
{predeclared_const} return P_CONST;
{predeclared_zero} return P_NIL;
{predeclared_functions} {yylval.P_FUNC = yytext; return P_FUNC;}
{identifier} {yylval.T_ID = strdup(yytext); return T_ID;}
{int_lit} {yylval.L_INT = atoi(yytext); return L_INT;}
{float_lit} {yylval.L_FLOAT = atof(yytext); return L_FLOAT;}
{rune_lit} {yylval.L_RUNE = strdup(yytext); return L_RUNE;}
{string_lit} {yylval.L_STRING = strdup(yytext); return L_STRING;}
. {printf("Everything else %s\n", yytext);}
