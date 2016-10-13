%option reentrant bison-bridge

%{
#include "parse.h"
%}

D [0-9]
E [Ee][+-]?{D}+

%%
[ \n\r\t]             ;
or[^a-zA-Z0-9_]       *yylval = nullptr; return Or;
and[^a-zA-Z0-9_]      *yylval = nullptr; return And;
div[^a-zA-Z0-9_]      *yylval = nullptr; return Div;
mod[^a-zA-Z0-9_]      *yylval = nullptr; return Mod;
\"(\\.|[^"])*\"       *yylval = ps->str(yytext); return String;
{D}+"."{D}+           |
{D}+"."{D}+{E}        *yylval = ps->float_(atof(yytext)); return Float;
{D}+                  *yylval = ps->int_(atoll(yytext)); return Int;
[0-9a-zA-Z_]+         *yylval = ps->id(yytext); return Identifier;
parent::              *yylval = nullptr; return Parent;
self::                *yylval = nullptr; return Self;
child::               *yylval = nullptr; return Child;
ancestor::            *yylval = nullptr; return Ancestor;
descendant::          *yylval = nullptr; return Descendant;
descendant-or-self::  *yylval = nullptr; return DescendantOrSelf;
"//"                  *yylval = nullptr; return DoubleSep;
"!="                  *yylval = nullptr; return NE;
"<="                  *yylval = nullptr; return LE;
">="                  *yylval = nullptr; return GE;
"$"                   |
"*"                   |
"+"                   |
"-"                   |
"["                   |
"]"                   |
"("                   |
")"                   |
,                     |
"|"                   |
"="                   |
"<"                   |
">"                   |
"/"                   *yylval = nullptr; return yytext[0];
