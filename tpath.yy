
%define api.value.type {AstNode*}

%token String Identifier Int Float
%token Or And NE LE GE Div Mod DoubleSep DoubleDot Node
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
TopLevel: Path { ps->result = $1; }

Path:
  RelPath
| AbsPath

AbsPath:
  '/' { $$ = ps->make(AstNode::AbsPath, {ps->make(AstNode::RelPath, {})}); }
| '/' RelPath { $$ = ps->make(AstNode::AbsPath, {$2}); }
| DoubleSep RelPath { $$ = ps->make_abbr_abs_path($2); }

RelPath:
  Step { $$ = ps->make(AstNode::RelPath, {$1}); }
| RelPath '/' Step { $1->add_child($3); $$ = $1; }
| RelPath DoubleSep Step { $$ = ps->make_abbr_rel_path($1, $3); }

Step:
  Axis NodeTest PredicateList { $$ = ps->make(AstNode::Step, {$1, $2, $3}); }
| NodeTest PredicateList { $$ = ps->make(AstNode::Step, {ps->make(Child), $1, $2}); }
| '.' { $$ = ps->make_any_node_step(Self); }
| DoubleDot { $$ = ps->make_any_node_step(Parent); }

PredicateList:
  /*empty*/ { $$ = ps->make(AstNode::PredicateList, {}); }
| PredicateList Predicate  { $1->add_child($2); $$ = $1; }

Predicate: '[' Expr ']' { $$ = $2; }

Axis:
  Parent
| Self
| Child
| Ancestor
| Descendant
| DescendantOrSelf

NodeTest:
  NameTest
| Node '(' ')' { $$ = $1; }

NameTest:
  Identifier
/*TODO*/

PrimaryExpr:
  VariableReference {}
| '(' Expr ')' { $$ = $2; }
| String
| Int
| Float
| FunctionCall

FunctionCall: Identifier '(' ArgList ')' { $$ = ps->make(AstNode::Call, {$1, $3}); }

ArgList:
  /*empty*/ { $$ = ps->make(AstNode::ArgList, {}); }
| NonEmptyArgList 

NonEmptyArgList:
  Expr { $$ = ps->make(AstNode::ArgList, {$1}); }
| NonEmptyArgList ',' Expr { $1->add_child($3); $$ = $1; }

VariableReference: '$' Identifier { $$ = ps->make('$', {$2}); }

Expr: OrExpr

OrExpr:
  AndExpr
| OrExpr Or AndExpr { $$ = ps->make(Or, {$1, $3}); }

AndExpr:
  EqualityExpr
| AndExpr And EqualityExpr { $$ = ps->make(And, {$1, $3}); }

EqualityExpr:
  RelationalExpr
| EqualityExpr '=' RelationalExpr { $$ = ps->make('=', {$1, $3}); }
| EqualityExpr NE RelationalExpr { $$ = ps->make(NE, {$1, $3}); }

RelationalExpr:
  AdditiveExpr
| RelationalExpr '<' AdditiveExpr { $$ = ps->make('<', {$1, $3}); }
| RelationalExpr '>' AdditiveExpr { $$ = ps->make('>', {$1, $3}); }
| RelationalExpr LE AdditiveExpr { $$ = ps->make(LE, {$1, $3}); }
| RelationalExpr GE AdditiveExpr { $$ = ps->make(GE, {$1, $3}); }

AdditiveExpr:
  MultiplicativeExpr
| AdditiveExpr '+' MultiplicativeExpr { $$ = ps->make('+', {$1, $3}); }
| AdditiveExpr '-' MultiplicativeExpr { $$ = ps->make('-', {$1, $3}); }

MultiplicativeExpr:
  UnaryExpr
| MultiplicativeExpr '*' UnaryExpr { $$ = ps->make('*', {$1, $3}); }
| MultiplicativeExpr Div UnaryExpr { $$ = ps->make(Div, {$1, $3}); }
| MultiplicativeExpr Mod UnaryExpr { $$ = ps->make(Mod, {$1, $3}); }

UnaryExpr:
  UnionExpr
| '-' UnaryExpr { $$ = ps->make('-', {$2}); }

UnionExpr:
  PathExpr
| UnionExpr '|' PathExpr { $$ = ps->make('|', {$1, $3}); }

PathExpr:
  Path
| FilterExpr
| FilterExpr '/' RelPath { $$ = ps->make('/', {$1, $3}); }
| FilterExpr DoubleSep RelPath { $$ = ps->make(DoubleSep, {$1, $3}); }

FilterExpr:
  PrimaryExpr
| FilterExpr Predicate { $$ = ps->make(AstNode::Filt, {$1, $2}); }

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


  printf("Top level node:\n");
  ps.result->print();

  return 0;
}
