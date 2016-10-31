#include <iostream>
#include <vector>
#include <memory>
#include "tpath.tab.hh"

struct Ast
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
      CASE(Mul)
      CASE(Div)
      CASE(Mod)
      CASE(DoubleSep)
      CASE(DoubleDot)
      CASE(Parent)
      CASE(Self)
      CASE(Child)
      CASE(Ancestor)
      CASE(Descendant)
      CASE(DescendantOrSelf)
      CASE(Filt)
      CASE(ArgList)
      CASE(Call)
      CASE(AbsPath)
      CASE(RelPath)
      CASE(Step)
      CASE(PredicateList)
#undef CASE
      default: return nullptr;
    }
  }

  int kind;
  int idx = 0;
  union
  {
    long long int_;
    double float_;
    std::string str;
    std::vector<std::shared_ptr<Ast>> children;
  };

  Ast(){}
  Ast(int kind, long long int_) : kind(kind), int_(int_), idx(0) {}
  Ast(int kind, double float_) : kind(kind), float_(float_), idx(1) {}
  Ast(int kind, const char* str) : kind(kind), str(str), idx(2) {}
  Ast(int kind, std::initializer_list<std::shared_ptr<Ast>> children)
  : kind(kind), children(), idx(3)
  {
    for(auto e : children)
    {
      this->children.push_back(e);
    }
  }

  Ast(const Ast& other) = delete;

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
 
  void add_child(std::shared_ptr<Ast> c) { children.push_back(c); }

  ~Ast()
  {
    if(idx == 2)
      str.~basic_string();
    else if(idx == 3)
      children.~vector();
  }
};

struct ParseState
{
  std::shared_ptr<Ast> result;

  std::shared_ptr<Ast> make(int kind, std::initializer_list<std::shared_ptr<Ast>> val)
  {
    return std::make_shared<Ast>(kind, val);
  }

  template<typename T>
  std::shared_ptr<Ast> make(int kind, T val)
  {
    return std::make_shared<Ast>(kind, val);
  }
  
  std::shared_ptr<Ast> make(int kind)
  {
    return std::make_shared<Ast>(kind, (long long) 0);
  }

  std::shared_ptr<Ast> make_abbr_abs_path(std::shared_ptr<Ast> rel_path)
  {
    auto& c = rel_path->children;
    c.insert(c.begin(), make_any_node_step(DescendantOrSelf));
    return make(Ast::AbsPath, {rel_path});
  }

  std::shared_ptr<Ast> make_abbr_rel_path(std::shared_ptr<Ast> rel_path, std::shared_ptr<Ast> step)
  {
    auto& c = rel_path->children;
    c.push_back(make_any_node_step(DescendantOrSelf));
    c.push_back(step);
    return rel_path;
  }

  std::shared_ptr<Ast> make_any_node_step(int axis)
  {
    return make(Ast::Step, { make(axis), make('*'), });
  }
};

std::shared_ptr<Ast> parse(FILE* file);
