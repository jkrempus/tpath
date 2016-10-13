#include <iostream>
#include <vector>
#include <memory>

struct AstNode
{
  enum { Int, Float, String, Identifier };

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
  AstNode(const AstNode& other) = delete;

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

  AstNode* float_(double val)
  {
    auto r = new AstNode;
    r->kind = AstNode::Float;
    r->float_ = val;
    nodes.emplace_back(r);
    return r;
  }
  
  AstNode* str(const char* val)
  {
    auto r = new AstNode;
    r->kind = AstNode::String;
    r->float_ = val;
    nodes.emplace_back(r);
    return r;
  }
};

