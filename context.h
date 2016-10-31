#include "parse.h"
#include "optional-lite/optional.hpp"
using nonstd::optional;
using nonstd::nullopt;
using nonstd::make_optional;

template<typename Iterator>
struct Range
{
  Iterator begin_;
  Iterator end_;
  Iterator begin(){ return begin_; }
  Iterator end(){ return end_; }
  Range advanced(int n = 1){ return { begin_ + n, end_ }; }
};

using AstRange = Range<const std::shared_ptr<Ast>*>;

AstRange children_range(const std::shared_ptr<Ast>& ast)
{
  return { &ast->children[0], &ast->children[0] + ast->children.size() };
}

template<typename Tree>
struct Context
{
  using node_type = typename Tree::node_type;

  struct NodeStorage
  {
    node_type node;
    std::string name;
    std::shared_ptr<NodeStorage> parent; 
  };

  using Node = std::shared_ptr<NodeStorage>;

  static Node make_node(
    const node_type& node,
    const std::string& name,
    const Node& parent)
  {
    auto r = std::make_shared<NodeStorage>();
    r->node = node;
    r->name = name;
    r->parent = parent;
    return r;
  }

  struct Value
  {
    optional<std::vector<Node>> nodes;
    optional<double> num;
    optional<std::string> str;
  };

  optional<std::string> err;

  bool node_accepted(
    const optional<std::string>& name,
    AstRange predicates,
    const Node& context_node)
  {
    if(!context_node) return false;
    return true;
  }

  void evaluate_path(
    AstRange path, const Node& context_node, std::vector<Node>& dst)
  {
    if(path.begin() == path.end()) dst.push_back(context_node);
    else
    {
      auto& step = *path.begin();
      auto& axis = step->children[0];
      optional<std::string> name;
      auto c = step->children[1].get();
      if(c->kind == Identifier || c->kind == String) name = c->str;
      auto predicates = children_range(step).advanced(2);

      auto recurse = [&](const Node& node)
      {
        bool accepted = node_accepted(name, predicates, node);
        if(err) return false;
        if(accepted)
        {
          evaluate_path(path.advanced(1), node, dst);
          if(err) return false;
        }

        return true;
      };

      if(axis->kind == Self)
      {
        if(!recurse(context_node)) return;
      }
      else if(axis->kind == Parent)
      {
        if(!recurse(context_node->parent)) return;
      }
      else if(axis->kind == Ancestor)
      {
        for(auto node = context_node->parent; node; node = node->parent)
          if(!recurse(node)) return;
      }
      else if(axis->kind == Child)
      {
        if(name)
        {
          if(auto opt = Tree::get_child(context_node->node, *name))
          {
            if(!recurse(make_node(*opt, *name, context_node))) return;
          }
        }
        else
        {
          Tree::iterate_children(context_node->node,
            [&](const node_type& node, const std::string& node_name)
          {
            return recurse(make_node(node, node_name, context_node));
          });

          if(err) return;
        }
      }
      else
      {
        std::vector<Node> stack; 
        stack.push_back(context_node);
        bool skip_next = axis->kind == Descendant;

        while(stack.size() > 0)
        {
          auto node = stack.back();
          stack.pop_back();

          if(!skip_next)
          {
            if(!recurse(node)) return;
          }

          skip_next = false;
          Tree::iterate_children(node->node,
            [&](const node_type& child_node, const std::string& child_name)
          {
            stack.push_back(make_node(child_node, child_name, context_node));
            return true;
          });
        }
      }
    }
  }

  Value evaluate_impl(
    const std::shared_ptr<Ast>& ast, const Node& context_node)
  {
    if(ast->kind == Ast::AbsPath)
    {
      auto node = context_node;
      for(; node->parent; node = node->parent) {}
      Value r;
      r.nodes = std::vector<Node>();
      evaluate_path(children_range(ast->children[0]), node, *r.nodes);
      return r;
    }
    else if(ast->kind == Ast::RelPath)
    {
      Value r;
      r.nodes = std::vector<Node>();
      evaluate_path(children_range(ast), context_node, *r.nodes);
      return r;
    }

    return Value();
  };

  Value evaluate(
    const std::shared_ptr<Ast>& ast, node_type node, const std::string& name)
  {
    return evaluate_impl(ast, make_node(node, name, nullptr));
  };
};