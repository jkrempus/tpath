%%
[ \n\r\t]             ;
or[^a-zA-Z0-9_]       return Or;
and[^a-zA-Z0-9_]      return And;
div[^a-zA-Z0-9_]      return Div;
mod[^a-zA-Z0-9_]      return Mod;
\"(\\.|[^"])*\"       return Literal;
[0-9]+                return Number; //TODO: Floats
[0-9a-zA-Z_]+         return Identifier;
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
