%union
{
  long long int_;
  double float_;
  char* str;
  void* parsed;
};

%token <str> String
%token <str> Identifier
%token <int_> Int
%token <float_> Float
%token Or And NE LE GE Div Mod DoubleSep
%token Parent Self Child Ancestor Descendant DescendantOrSelf
%type <parsed> PrimaryExpr

%debug
%error-verbose

%code requires 
{
  typedef void* yyscan_t;
  struct ParseState;
}

%{
  #include "parse.h"
%}

%define api.pure full
%lex-param {yyscan_t scanner}
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
    std::cout << "path segment" << std::endl;
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
  std::cout << "NodeTest " << $1 << "()" << std::endl;
}
/*TODO*/

NameTest:
  Identifier
/*TODO*/

PrimaryExpr:
  VariableReference {}
| '(' Expr ')' {}
| String {}                 
| Int { printf("int %lld\n", $1); $$ = nullptr; }
| Float { printf("float %lf\n", $1); $$ = nullptr; }
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
  PrimaryExpr
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
