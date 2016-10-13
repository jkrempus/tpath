#include <iostream>
#include <vector>
#include <memory>
#include "tpath.tab.hh"

struct AstNode
{
  enum
  {
    Neg = DescendantOrSelf + 1,
    Filt
  };

  int kind;
  bool is_root = true;
  union
  {
    double float_;
    long long int_;
    std::string str;
    std::vector<AstNode*> children;
  };

  AstNode(){}
  AstNode(int kind, double float_) : kind(kind), float_(float_) {}
  AstNode(int kind, long long int_) : kind(kind), int_(int_) {}
  AstNode(int kind, const char* str) : kind(kind), str(str) {}
  AstNode(int kind, std::initializer_list<AstNode*> children)
  : kind(kind), children()
  {
    for(auto e : children)
    {
      e->is_root = false;
      this->children.emplace_back(e);
    }
  }

  AstNode(const AstNode& other) = delete;

  void print(int indent = 0)
  {
    for(ptrdiff_t i = 0; i < indent; i++) printf("  ");
   
    printf("%d ", kind);
    if(kind == String || kind == Identifier) printf("%s\n", str.c_str());
    else if(kind == Int) printf("%lld\n", int_);
    else if(kind == Float) printf("%lf\n", float_);
    else
    {
      printf("node\n");
      for(auto e : children) e->print(indent + 1);
    }
  }
 
  void add_child(AstNode* c)
  {
    c->is_root = false;
    children.emplace_back(c);
  }

  ~AstNode()
  {
    if(kind == String || kind == Identifier)
      str.~basic_string();
    else if(kind != Int && kind != Float)
      children.~vector();
  }
};

struct ParseState
{
  std::vector<std::unique_ptr<AstNode>> nodes;

  AstNode* add(AstNode* a)
  {
    nodes.emplace_back(a);
    return a;
  }

  AstNode* float_(double val) { return add(new AstNode(Float, val)); }
  AstNode* int_(long long val) { return add(new AstNode(Int, val)); }
  AstNode* str(const char* s) { return add(new AstNode(String, s)); }
  AstNode* id(const char* s) { return add(new AstNode(Identifier, s)); }
  AstNode* neg(AstNode* a) { return add(new AstNode(AstNode::Neg, {a})); }
  AstNode* filt(AstNode* f, AstNode* pred)
  { return add(new AstNode(AstNode::Filt, {f, pred})); }
  AstNode* sep(AstNode* a, AstNode* b) { return add(new AstNode('/', {a, b})); }
  AstNode* double_sep(AstNode* a, AstNode* b)
  { return add(new AstNode('/', {a, b})); }
  AstNode* mul(AstNode* a, AstNode* b) { return add(new AstNode('*', {a, b})); }
  AstNode* div(AstNode* a, AstNode* b) { return add(new AstNode(Div, {a, b})); }
  AstNode* mod(AstNode* a, AstNode* b) { return add(new AstNode(Mod, {a, b})); }
  AstNode* union_(AstNode* a, AstNode* b)
  { return add(new AstNode('|', {a, b})); }
  AstNode* sum(AstNode* a, AstNode* b) { return add(new AstNode('+', {a, b})); }
  AstNode* dif(AstNode* a, AstNode* b) { return add(new AstNode('-', {a, b})); }
  AstNode* parens(AstNode* a) { return add(new AstNode('-', {a})); }
};
