
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
    (YYSTYPE * yylval_param, yyscan_t yyscanner, ParseState* parse_state)
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
%lex-param {yyscan_t scanner} {ParseState* parse_state}
%parse-param {yyscan_t scanner} {ParseState* parse_state}

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
{
}
/*TODO*/

NameTest:
  Identifier
/*TODO*/

PrimaryExpr:
  VariableReference {}
| '(' Expr ')' {}
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

Expr: OrExpr

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
| AdditiveExpr '+' MultiplicativeExpr
| AdditiveExpr '-' MultiplicativeExpr

MultiplicativeExpr:
  UnaryExpr
| MultiplicativeExpr '*' UnaryExpr
| MultiplicativeExpr Div UnaryExpr
| MultiplicativeExpr Mod UnaryExpr

UnaryExpr:
  UnionExpr
| '-' UnaryExpr

UnionExpr:
  PathExpr
| UnionExpr '|' PathExpr

PathExpr:
  Path
| FilterExpr
| FilterExpr '/' RelPath
| FilterExpr DoubleSep RelPath

FilterExpr:
  PrimaryExpr { if($1 && $1->kind == Float) printf("float %lf\n", $1->float_); $$ = $1; }
| FilterExpr Predicate

%%

int main ()
{
  ParseState parse_state;
  yyscan_t scanner;
  int tok;

  yylex_init(&scanner);
  yyset_in(stdin, scanner );

  while(!feof(stdin)) yyparse(scanner, &parse_state);

  yylex_destroy(scanner);
  return 0;
}
