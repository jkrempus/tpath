#include "parse.h"

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

template<typename Tree>
struct Context
{
  void evaluate_path(
    Ast* ast, ptrdiff_t idx, const Node<Tree>& context_node,
    std::vector<Node<Tree>>& dst)
  {
    if(idx == ast->children.size())
    {
      dst.push(context_node);
    }
    else
    {
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
