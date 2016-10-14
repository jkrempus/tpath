#include <iostream>
#include <vector>
#include <memory>
#include "tpath.tab.hh"

struct AstNode
{
  enum
  {
    Filt = DescendantOrSelf + 1,
    ArgList,
    Call,
    AbsPath,
    RelPath,
    Step,
    PredicateList
  };

  static const char* enum_to_str(int val)
  {
    switch(val)
    {
#define CASE(s) case s: return #s;
      CASE(String)
      CASE(Identifier)
      CASE(Int)
      CASE(Float)
      CASE(Or)
      CASE(And)
      CASE(NE)
      CASE(LE)
      CASE(GE)
      CASE(Div)
      CASE(Mod)
      CASE(DoubleSep)
      CASE(DoubleDot)
      CASE(DoubleColon)
      CASE(Parent)
      CASE(Self)
      CASE(Child)
      CASE(Ancestor)
      CASE(Descendant)
      CASE(DescendantOrSelf)
      CASE(Filt)
      CASE(ArgList)
      CASE(Call)
      CASE(Node)
      CASE(AbsPath)
      CASE(RelPath)
      CASE(Step)
      CASE(PredicateList)
#undef CASE
      default: return nullptr;
    }
  }

  int kind;
  bool is_root = true;
  int idx = 0;
  union
  {
    long long int_;
    double float_;
    std::string str;
    std::vector<AstNode*> children;
  };

  AstNode(){}
  AstNode(int kind, long long int_) : kind(kind), int_(int_), idx(0) {}
  AstNode(int kind, double float_) : kind(kind), float_(float_), idx(1) {}
  AstNode(int kind, const char* str) : kind(kind), str(str), idx(2) {}
  AstNode(int kind, std::initializer_list<AstNode*> children)
  : kind(kind), children(), idx(3)
  {
    for(auto e : children)
    {
      e->is_root = false;
      this->children.push_back(e);
    }
  }

  AstNode(const AstNode& other) = delete;

  void print(int indent = 0)
  {
    for(ptrdiff_t i = 0; i < indent; i++) printf("  ");
  
    if(std::isprint(kind)) 
      printf("'%c' ", kind);
    else
      printf("%s ", enum_to_str(kind));

    if(idx == 2) printf("%s\n", str.c_str());
    else if(idx == 0) printf("%lld\n", int_);
    else if(idx == 1) printf("%lf\n", float_);
    else
    {
      printf("node\n");
      for(auto e : children) e->print(indent + 1);
    }
  }
 
  void add_child(AstNode* c)
  {
    c->is_root = false;
    children.push_back(c);
  }

  ~AstNode()
  {
    if(idx == 2)
      str.~basic_string();
    else if(idx == 2)
      children.~vector();
  }
};

struct ParseState
{
  std::vector<std::unique_ptr<AstNode>> nodes;

  AstNode* make(int kind, std::initializer_list<AstNode*> val)
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
  
  AstNode* make(int kind)
  {
    auto r = new AstNode(kind, (long long) 0);
    nodes.emplace_back(r);
    return r;
  }

  AstNode* make_abbr_abs_path(AstNode* rel_path)
  {
    auto& c = rel_path->children;
    c.insert(c.begin(), make_any_node_step(DescendantOrSelf));
    return make(AstNode::AbsPath, {rel_path});
  }
  
  AstNode* make_abbr_rel_path(AstNode* rel_path, AstNode* step)
  {
    auto& c = rel_path->children;
    c.push_back(make_any_node_step(DescendantOrSelf));
    c.push_back(step);
    return rel_path;
  }

  AstNode* make_any_node_step(int axis)
  {
    return make(AstNode::Step,
    {
      make(axis),
      make(Node),
      make(AstNode::PredicateList, {})
    });
  }
};
