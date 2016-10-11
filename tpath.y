%token Literal Number Identifier Or And NE LE GE Div Mod DoubleSep
%token Parent Self Child Ancestor Descendant DescendantOrSelf

%error-verbose

%%
Path                : RelPath
                    | AbsPath

AbsPath             : '/'
                    | '/' RelPath
                    /*TODO AbbrAbsPath*/

RelPath             : Step
                    | AbsPath
                    /*TODO AbbrRelPath*/

Step                : AxisSpec NodeTest PredicateList 
                    /*TODO AbbrStep*/

PredicateList       : /*empty*/
                    | PredicateList Predicate 

Predicate           : '[' Expr ']'

AxisSpec            : Axis
                    /*TODO AbbrAxisSpec*/

Axis                : Parent
                    | Self
                    | Child
                    | Ancestor
                    | Descendant
                    | DescendantOrSelf

NodeTest            : NameTest
                    /*TODO*/

NameTest            : Identifier
                    /*TODO*/

PrimaryExpr         : VariableReference
                    | '(' Expr ')'
                    | Literal                 
                    | Number                    
                    | FunctionCall

FunctionCall        : Identifier '(' ArgList ')'

ArgList             : /*empty*/
                    | NonEmptyArgList 

NonEmptyArgList     : Expr
                    | NonEmptyArgList ',' Expr

VariableReference   : '$' Identifier

Expr                : OrExpr

OrExpr              : AndExpr
                    | OrExpr Or AndExpr

AndExpr             : EqualityExpr
                    | AndExpr And EqualityExpr

EqualityExpr        : RelationalExpr
                    | EqualityExpr '=' RelationalExpr
                    | EqualityExpr NE RelationalExpr

RelationalExpr      : AdditiveExpr
                    | RelationalExpr '<' AdditiveExpr
                    | RelationalExpr '>' AdditiveExpr
                    | RelationalExpr LE AdditiveExpr
                    | RelationalExpr GE AdditiveExpr

AdditiveExpr        : MultiplicativeExpr
                    | AdditiveExpr '+' MultiplicativeExpr
                    | AdditiveExpr '-' MultiplicativeExpr

MultiplicativeExpr  : UnaryExpr
                    | MultiplicativeExpr '*' UnaryExpr
                    | MultiplicativeExpr Div UnaryExpr
                    | MultiplicativeExpr Mod UnaryExpr

UnaryExpr           : UnionExpr
                    | '-' UnaryExpr

UnionExpr           : PathExpr
                    | UnionExpr '|' PathExpr

PathExpr            : Path
                    | FilterExpr
                    | FilterExpr '/' RelPath
                    | FilterExpr DoubleSep RelPath

FilterExpr          : PrimaryExpr
                    | FilterExpr Predicate

%%
#include "lex.yy.c"
