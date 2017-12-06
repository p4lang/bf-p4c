#include "bf-p4c/common/linear_path.h"

namespace BFN {

Visitor::profile_t PathLinearizer::init_apply(const IR::Node* root) {
    BUG_CHECK(root->is<IR::PathExpression>() ||
              root->is<IR::Member>(),
              "Applying PathlikeExpressionAnalyzer to non-path-like "
              "expression: %1%", root);
    linearPath.emplace();
    return Inspector::init_apply(root);
}

void PathLinearizer::postorder(const IR::Path*) {
    // Just ignore Paths; they'll be represented by the PathExpressions that
    // contain them.
}

void PathLinearizer::postorder(const IR::PathExpression* path) {
    if (linearPath) linearPath->components.push_back(path);
}

void PathLinearizer::postorder(const IR::Member* member) {
    if (linearPath) linearPath->components.push_back(member);
}

void PathLinearizer::postorder(const IR::Node* node) {
    LOG2("Marking path-like expression invalid due to component: " << node);
    linearPath = boost::none;
}

void PathLinearizer::end_apply() {
    if (!linearPath) return;
    if (linearPath->components.empty()) {
        linearPath = boost::none;
        return;
    }
    if (!linearPath->components[0]->is<IR::PathExpression>()) {
        LOG2("Marking path-like expression invalid due to first component: "
             << linearPath->components[0]);
        linearPath = boost::none;
        return;
    }
}

}  // namespace BFN
