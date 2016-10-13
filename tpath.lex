%option reentrant bison-bridge

%{
#include "tpath.tab.hh"
%}

D [0-9]
E [Ee][+-]?{D}+

%%
[ \n\r\t]             ;
or[^a-zA-Z0-9_]       return Or;
and[^a-zA-Z0-9_]      return And;
div[^a-zA-Z0-9_]      return Div;
mod[^a-zA-Z0-9_]      return Mod;
\"(\\.|[^"])*\"       { yylval->str = strdup(yytext); return String; }
{D}+"."{D}+           |
{D}+"."{D}+{E}        { yylval->float_ = atof(yytext); return Float; }
{D}+                  { yylval->int_ = atoll(yytext); return Int; }
[0-9a-zA-Z_]+         { yylval->str = strdup(yytext); return Identifier; }
parent::              return Parent;
self::                return Self;
child::               return Child;
ancestor::            return Ancestor;
descendant::          return Descendant;
descendant-or-self::  return DescendantOrSelf;
"//"                  return DoubleSep;
"!="                  return NE;
"<="                  return LE;
">="                  return GE;
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
"/"                   return yytext[0];
