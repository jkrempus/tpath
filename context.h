#include "parse.h"
#include "optional-lite/optional.hpp"
#include "variant-lite/include/nonstd/variant.hpp"

#include <unordered_map>

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
  using NodeVec = std::vector<Node>;

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

  class Value
  {
    using Variant = nonstd::variant<NodeVec, double, std::string>;
    std::shared_ptr<Variant> ptr;

  public:
    Value() = default;
    Value(double a) : ptr(new Variant(a)) {} 
    Value(const std::string& a) : ptr(new Variant(a)) {} 
    Value(const NodeVec& a) : ptr(new Variant(a)) {}
    Value(NodeVec&& a) : ptr(new Variant(std::move(a))) {}

    NodeVec* nodes() { return nonstd::get_if<NodeVec>(ptr.get()); }
    std::string* str() { return nonstd::get_if<std::string>(ptr.get()); }
    double* num() { return nonstd::get_if<double>(ptr.get()); }
    bool none() { return ptr == nullptr; }
  };

  struct Function
  {
    virtual Value call(
      Context* context,
      const Node& context_node, 
      const Value* args,
      int num_args) = 0;
  };

  nonstd::optional<std::string> err;
  std::unordered_map<std::string, std::unique_ptr<Function>> functions;

  bool node_accepted(
    const nonstd::optional<std::string>& name,
    AstRange predicates,
    const Node& context_node)
  {
    if(!context_node) return false;

    for(auto& e : predicates)
      if(evaluate_impl(e, context_node).none()) return false;

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
      nonstd::optional<std::string> name;
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
            stack.push_back(make_node(child_node, child_name, node));
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
      auto r = Value(NodeVec());
      evaluate_path(children_range(ast->children[0]), node, *r.nodes());
      return r;
    }
    else if(ast->kind == Ast::RelPath)
    {
      auto r = Value(NodeVec());
      evaluate_path(children_range(ast), context_node, *r.nodes());
      return r;
    }
    else if(ast->kind == Ast::Call)
    {
      auto& c = ast->children;
      assert(c.size() >= 1 && c[0]->kind == Identifier);
      auto name = c[0]->str;
      auto fn_it = functions.find(name);
      if(fn_it == functions.end())
      {
        err = "Unknown function " + name;
        return Value();
      }

      std::vector<Value> args;
      for(ptrdiff_t i = 1; i < c.size(); i++)
        args.push_back(evaluate_impl(c[i], context_node));

      return fn_it->second->call(this, context_node, &args[0], args.size());
    }
    else if(ast->kind == Number) return Value(ast->num);
    else if(ast->kind == String) return Value(ast->str);

    return Value();
  };

  Value evaluate(
    const std::shared_ptr<Ast>& ast, node_type node, const std::string& name)
  {
    return evaluate_impl(ast, make_node(node, name, nullptr));
  };
};
