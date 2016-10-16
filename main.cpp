#include "parse.h"

template<typename Tree, typename Callback>
void iterate(AstNode* ast, const Callback& callback)
{
  
};

int main(int argc, char** argv)
{
  auto ast = parse(argc > 1 ? fopen(argv[1], "r") : stdin);
  printf("Top level node:\n");
  ast->print();
  return 0;
}
