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
\"(\\.|[^"])*\"       *yylval = ps->make(String, yytext); return String;
{D}+"."{D}+           |
{D}+"."{D}+{E}        *yylval = ps->make(Float, atof(yytext)); return Float;
{D}+                  *yylval = ps->make(Int, atoll(yytext)); return Int;
[0-9a-zA-Z_]+         *yylval = ps->make(Identifier, yytext); return Identifier;
parent::              *yylval = ps->make(Parent); return Parent;
self::                *yylval = ps->make(Self); return Self;
child::               *yylval = ps->make(Child); return Child;
ancestor::            *yylval = ps->make(Ancestor); return Ancestor;
descendant::          *yylval = ps->make(Descendant); return Descendant;
descendant-or-self::  *yylval = ps->make(DescendantOrSelf); return DescendantOrSelf;
"//"                  *yylval = nullptr; return DoubleSep;
".."                  *yylval = nullptr; return DoubleDot;
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
"."                   |
"/"                   *yylval = nullptr; return yytext[0];
