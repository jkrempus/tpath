#include <iostream>
#include <vector>
#include <memory>
#include "tpath.tab.hh"

struct AstNode
{
  enum
  {
    Filt = DescendantOrSelf + 1
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
  
    if(std::isprint(kind)) 
      printf("'%c' ", kind);
    else
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

  template<typename T>
  AstNode* make(int kind, std::initializer_list<T> val)
  {
    auto r = new AstNode(kind, val);
    nodes.emplace_back(r);
    return r;
  }

  template<typename T>
  AstNode* make(int kind, T val)
  {
    auto r = new AstNode(kind, val);
    nodes.emplace_back(r);
    return r;
  }
};
