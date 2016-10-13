
%define api.value.type {AstNode*}

%token String Identifier Int Float
%token Or And NE LE GE Div Mod DoubleSep
%token Parent Self Child Ancestor Descendant DescendantOrSelf

%debug
%error-verbose

%code requires 
{
  struct AstNode;
  struct ParseState;
  typedef void* yyscan_t;

  #define YY_DECL int yylex \
    (YYSTYPE * yylval_param, yyscan_t yyscanner, ParseState* ps)
}

%{
  #include "parse.h"
  extern "C"
  {
    int yylex_init(yyscan_t);
    int yylex_destroy(yyscan_t);
    int yyset_in(FILE*, yyscan_t);
  }

  int yylex(YYSTYPE*, yyscan_t, ParseState*);
  void yyerror(yyscan_t, yyscan_t, const char *s){}
%}

%define api.pure full
%lex-param {yyscan_t scanner} {ParseState* ps}
%parse-param {yyscan_t scanner} {ParseState* ps}

%%
Path:
  RelPath
| AbsPath

AbsPath:
  '/'
| '/' RelPath
/*TODO AbbrAbsPath*/

RelPath:
  Step
| RelPath '/' Step
  {
  }
/*TODO AbbrRelPath*/

Step:
  AxisSpec NodeTest PredicateList 
/*TODO AbbrStep*/

PredicateList:
  /*empty*/
| PredicateList Predicate 

Predicate: '[' Expr ']'

AxisSpec:
  Axis
/*TODO AbbrAxisSpec*/

Axis:
  Parent
| Self
| Child
| Ancestor
| Descendant
| DescendantOrSelf

NodeTest:
  NameTest
| Identifier '(' ')'
/*TODO*/

NameTest:
  Identifier
/*TODO*/

PrimaryExpr:
  VariableReference {}
| '(' Expr ')' { $$ = ps->parens($2); }
| String {}                 
| Int
| Float
| FunctionCall {}

FunctionCall: Identifier '(' ArgList ')'

ArgList:
  /*empty*/
| NonEmptyArgList 

NonEmptyArgList:
  Expr
| NonEmptyArgList ',' Expr

VariableReference: '$' Identifier

Expr: OrExpr { if($1) { printf("Expr\n"); $1->print(); } $$ = $1; }

OrExpr:
  AndExpr
| OrExpr Or AndExpr

AndExpr:
  EqualityExpr
| AndExpr And EqualityExpr

EqualityExpr:
  RelationalExpr
| EqualityExpr '=' RelationalExpr
| EqualityExpr NE RelationalExpr

RelationalExpr:
  AdditiveExpr
| RelationalExpr '<' AdditiveExpr
| RelationalExpr '>' AdditiveExpr
| RelationalExpr LE AdditiveExpr
| RelationalExpr GE AdditiveExpr

AdditiveExpr:
  MultiplicativeExpr
| AdditiveExpr '+' MultiplicativeExpr { $$ = ps->sum($1, $3); }
| AdditiveExpr '-' MultiplicativeExpr { $$ = ps->dif($1, $3); }

MultiplicativeExpr:
  UnaryExpr
| MultiplicativeExpr '*' UnaryExpr { $$ = ps->mul($1, $3); }
| MultiplicativeExpr Div UnaryExpr { $$ = ps->div($1, $3); }
| MultiplicativeExpr Mod UnaryExpr { $$ = ps->mod($1, $3); }

UnaryExpr:
  UnionExpr
| '-' UnaryExpr { $$ = ps->neg($2); }

UnionExpr:
  PathExpr
| UnionExpr '|' PathExpr { $$ = ps->union_($1, $3); }

PathExpr:
  Path
| FilterExpr
| FilterExpr '/' RelPath { $$ = ps->sep($1, $3); }
| FilterExpr DoubleSep RelPath { $$ = ps->double_sep($1, $3); }

FilterExpr:
  PrimaryExpr
| FilterExpr Predicate { $$ = ps->filt($1, $2); }

%%

int main (int argc, char** argv)
{
  ParseState ps;
  yyscan_t scanner;
  int tok;

  yylex_init(&scanner);
  yyset_in(argc > 1 ? fopen(argv[1], "r") : stdin, scanner );

  while(!feof(stdin)) yyparse(scanner, &ps);

  yylex_destroy(scanner);
  return 0;
}
