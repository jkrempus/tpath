%option reentrant bison-bridge

%{
#include "parse.h"
#define unput_last unput(yytext[strlen(yytext) - 1])
%}

D [0-9]
E [Ee][+-]?{D}+
NW [^a-zA-Z0-9_]

%%
[ \n\r\t]             ;
or{NW}                unput_last; *yylval = nullptr; return Or;
and{NW}               unput_last; *yylval = nullptr; return And;
div{NW}               unput_last; *yylval = nullptr; return Div;
mod{NW}               unput_last; *yylval = nullptr; return Mod;
mul{NW}               unput_last; *yylval = ps->make(Mul); return Mul;
parent::              *yylval = ps->make(Parent); return Parent;
self::                *yylval = ps->make(Self); return Self;
child::               *yylval = ps->make(Child); return Child;
ancestor::            *yylval = ps->make(Ancestor); return Ancestor;
descendant::          *yylval = ps->make(Descendant); return Descendant;
descendant-or-self::  *yylval = ps->make(DescendantOrSelf); return DescendantOrSelf;
\"(\\.|[^"])*\"       *yylval = ps->make(String, yytext); return String;
{D}+"."{D}+           |
{D}+"."{D}+{E}        *yylval = ps->make(Float, atof(yytext)); return Float;
{D}+                  *yylval = ps->make(Int, atoll(yytext)); return Int;
[0-9a-zA-Z_]+         *yylval = ps->make(Identifier, yytext); return Identifier;
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
