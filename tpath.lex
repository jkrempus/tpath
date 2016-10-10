%%
[ \n\r\t]             ;
\/                    printf("[PATHSEP]");
\"(\\.|[^"])*\"       printf("[LITERAL \"%s\"]", yytext);
[0-9]+                printf("[INT %d]", atoi(yytext));
[0-9a-zA-Z_]+         printf("[IDENTIFIER]");
parent::              printf("[PARENT]");
self::                printf("[SELF]");
child::               printf("[CHILD]");
ancestor::            printf("[ANCESTOR]");
descendant::          printf("[DESCENDANT]");
descendant-or-self::  printf("[DESCENDANT-OR-SELF]");
"["                   printf("[LBRACK]");
"]"                   printf("[RBRACK]");
"("                   printf("[LPAR]");
")"                   printf("[RPAR]");
,                     printf("[COMA]");
"|"                   printf("[PIPE]");


