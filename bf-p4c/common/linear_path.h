#ifndef BF_P4C_COMMON_LINEAR_PATH_H_
#define BF_P4C_COMMON_LINEAR_PATH_H_

#include <boost/optional.hpp>
#include <vector>
#include "ir/ir.h"

namespace P4 {
class TypeMap;
}  // namespace P4

namespace BFN {

/**
 * A linearization of a path-like expression which can be used to iterate over
 * the components of a nested Member expression in left-to-right order.
 *
 * Using an ML-like notation, the IR for the P4 expression `foo.bar.baz` looks
 * something like this:
 *
 *     Member (Member (PathExpression "foo") "bar") "baz"
 *
 * LinearPath represents the same expression as a sequence of components like
 * this:
 *
 *     [ PathExpression "foo", Member "bar", Member "baz" ]
 *
 * Each component in the sequence is just a pointer to the original IR node
 * corresponding to that component, so inspecting them with a normal visitor is
 * still possible, and you can still look them up in a ReferenceMap or TypeMap.
 *
 * The first component is always a PathExpression, and the remaining components
 * are always Member expressions.
 *
 * XXX(seth): Perhaps it'd be nice to support indexing into header stacks as
 * well.
 */
struct LinearPath {
    std::vector<const IR::Expression*> components;
};

/**
 * Construct a LinearPath from a path-like expression.
 *
 * A valid path-like expression contains only Path, PathExpression, and Member
 * nodes, it must contain at least one such node, and its linearization must
 * start with a PathExpression.
 *
 * XXX(seth): Perhaps it'd be nice to support indexing into header stacks as
 * well.
 *
 * If the expression being visited is a valid path-like expression,
 * `PathLinearizer::linearPath` will contain the linearized version of the path.
 * If the expression is not path-like, `linearPath` will contain `boost::none`.
 */
struct PathLinearizer : public Inspector {
    boost::optional<LinearPath> linearPath;

 private:
    profile_t init_apply(const IR::Node* root) override;
    void postorder(const IR::Path*) override;
    void postorder(const IR::PathExpression* path) override;
    void postorder(const IR::Member* member) override;
    void postorder(const IR::Node* node) override;
    void end_apply() override;
};

}  // namespace BFN

#endif  /* BF_P4C_COMMON_LINEAR_PATH_H_ */
