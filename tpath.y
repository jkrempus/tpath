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
