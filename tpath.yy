%union
{
  long long int_;
  char* str;
};

%token <str> Literal
%token <str> Identifier
%token <int_> Number
%token Or And NE LE GE Div Mod DoubleSep
%token Parent Self Child Ancestor Descendant DescendantOrSelf

%debug
%error-verbose


%{
  #include <iostream>
  typedef void* yyscan_t;
  #include "tpath.tab.hh"
  extern "C"
  {
   int yylex(YYSTYPE*, yyscan_t);
   int yylex_init(yyscan_t);
   int yylex_destroy(yyscan_t);
   int yyset_in(FILE*, yyscan_t);
  }
  void yyerror(yyscan_t, const char *s){}
%}

%define api.pure full
%lex-param {void* scanner}
%parse-param {void* scanner}

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
  VariableReference
| '(' Expr ')'
| Literal                 
| Number                    
| FunctionCall

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
  yyscan_t scanner;
  int tok;

  yylex_init(&scanner);
  yyset_in(stdin, scanner );

  while(!feof(stdin)) yyparse(scanner);

  yylex_destroy(scanner);
  return 0;
}
