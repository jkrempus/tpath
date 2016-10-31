#include "parse.h"
#include "optional-lite/optional.hpp"
using nonstd::optional;
using nonstd::nullopt;
using nonstd::make_optional;

template<typename Tree>
struct Node
{
  typename Tree::node node;
  std::string name;
  std::shared_ptr<Node> parent; 
};

template<typename Tree>
struct Value
{
  std::vector<Node<Tree>> node;
  double num;
  std::string str;
};

struct AstRange
{
  const std::shared_ptr<Ast>* begin_;
  const std::shared_ptr<Ast>* end_;
  const std::shared_ptr<Ast>* begin(){ return begin_; }
  const std::shared_ptr<Ast>* end(){ return end_; }
  AstRange advanced(int n = 1){ return { begin_ + n, end_ }; }
  static AstRange from_vec(
    const std::vector<std::shared_ptr<Ast>>& vec)
  {
    return { &vec[0], &vec[0] + vec.size() };
  }
};

template<typename Tree>
struct Context
{

  bool node_accepted(
    const optional<std::string>& name,
    AstRange predicates,
    const Node<Tree>& context_node)
  {
  }

  void axis_descendant(
    AstRange path, const optional<std::string>& name, AstRange predicates,
    const Node<Tree>& context_node, std::vector<Node<Tree>>& dst)
  {
  }

  void evaluate_path(
    AstRange path, const Node<Tree>& context_node,
    std::vector<Node<Tree>>& dst)
  {
    if(path.begin() == path.end()) dst.push(context_node);
    else
    {
      auto step = path.begin()->get();
      auto axis = step->children[0].get();
      optional<std::string> name;
      auto c = step->children[1].get();
      if(c->kind == Identifier || c->kind == String) name = c->str;
      auto predicates = AstRange::from_vec(step->children).advanced(2);

      //Parent | Self | Child | Ancestor | Descendant | DescendantOrSelf
      if(axis->kind == Parent)
      {
        auto parent_node = context_node.parent;
        if(node_accepted(name, predicates, parent_node))
          evaluate_path(path.advanced(1), parent_node, dst);
      }
      else if(axis->kind == Ancestor)
      {
        for(auto node = context_node.parent; node; node = node->parent)
          if(node_accepted(name, predicates, node))
            evaluate_path(path.advanced(1), node, dst);
      }
      else if(axis->kind == Child)
      {
        Tree::iterate_children(context_node,
          [&](const typename Tree::node& node, const std::string& str)
        {
          
        });
      }
      else
      {
        if(axis->kind == Self || axis->kind == DescendantOrSelf)
          if(node_accepted(name, predicates, context_node))
            evaluate_path(path.advanced(1), context_node, dst);

        if(axis->kind == Descendant || axis->DescendantOrSelf)
        {
          
        }
      }
    }
  };

  Value<Tree> evaluate(Ast* ast, const Node<Tree>& context_node)
  {
    return Value<Tree>();
  };
};

int main(int argc, char** argv)
{
  auto ast = parse(argc > 1 ? fopen(argv[1], "r") : stdin);
  printf("Top level node:\n");
  ast->print();
  return 0;
}
