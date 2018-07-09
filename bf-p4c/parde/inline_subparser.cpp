#include "bf-p4c/parde/inline_subparser.h"

namespace {

class CollectInlineSubparser : public Inspector {
    class VisitFollowingStates {
        const IR::ParserState* start_from;
        P4::ReferenceMap *refMap;
        std::function<void(const IR::ParserState*)> func;
        std::set<const IR::ParserState*> visited;

        void visit(const IR::ParserState* state) {
            if (visited.count(state)) {
                return; }
            visited.insert(state);

            func(state);

            for (const auto* next : getNextStates(refMap, state)) {
                visit(next); }
        }

     public:
        void run(const std::function<void(const IR::ParserState*)>& f) {
            visited.clear();
            func = f;
            visit(start_from);
        }

     public:
        VisitFollowingStates(const IR::ParserState* start_from,
                             P4::ReferenceMap *refMap)
            : start_from(start_from), refMap(refMap) { }
    };

 public:
    static std::vector<const IR::ParserState*>
    getNextStates(P4::ReferenceMap *refMap, const IR::ParserState* state) {
        std::vector<const IR::ParserState*> rst;
        if (state->selectExpression) {
            if (auto* next = state->selectExpression->to<IR::PathExpression>()) {
                auto* next_state = refMap->getDeclaration(next->path)->to<IR::ParserState>();
                rst.push_back(next_state);
            } else if (auto* select = state->selectExpression->to<IR::SelectExpression>()) {
                for (const auto* select_case : select->selectCases) {
                    auto* transition_to =
                        refMap->getDeclaration(select_case->state->path)->to<IR::ParserState>();
                    rst.push_back(transition_to);
                }
            }
        }
        return rst;
    }

 private:
    std::pair<cstring, cstring>
    getAssignNames(const IR::AssignmentStatement* assign) const {
        auto* rhs = assign->right;
        auto* lhs = assign->left;
        if (auto* lhs_path = lhs->to<IR::PathExpression>()) {
            cstring dest = lhs_path->path->name;
            if (auto* rhs_path = rhs->to<IR::PathExpression>()) {
                cstring src = rhs_path->path->name;
                return { dest, src };
            }
        }
        return std::make_pair("", "");
    }

    bool hasUse(const IR::ParserState* state, cstring inst) const {
        bool has_use = false;
        forAllMatching<IR::MethodCallExpression>(
                &state->components, [&] (const IR::MethodCallExpression* call_expr) {
                    forAllMatching<IR::PathExpression>(
                            call_expr, [&] (const IR::PathExpression* path) {
                                if (path->path->name.name == inst) {
                                    has_use = true; }
                            }); });
        forAllMatching<IR::SelectExpression>(
                &state->components, [&] (const IR::SelectExpression* call_expr) {
                    forAllMatching<IR::PathExpression>(
                            call_expr, [&] (const IR::PathExpression* path) {
                                if (path->path->name.name == inst) {
                                    has_use = true; }
                            }); });
        return has_use;
    }

    bool hasAssign(const IR::ParserState* state, cstring dest, cstring src) const {
        bool has_copy = false;
        forAllMatching<IR::AssignmentStatement>(
                state, [&] (const IR::AssignmentStatement* assign) {
                    cstring s, d;
                    std::tie(d, s) = getAssignNames(assign);
                    if (dest == d && src == s) {
                        has_copy = true; } });
        return has_copy;
    }

    bool neverUseBefore(const std::vector<const IR::ParserState*>& stack,
                        cstring dest,
                        cstring src) const {
        if (!stack.size()) return true;
        for (auto i = stack.rbegin() + 1; i < stack.rend(); ++i) {
            auto* state = (*i);
            // If this state is where value copied in, do not check further.
            if (hasAssign(state, src, dest)) {
                LOG3("Check stops at, state->name = " << state->name);
                break; }
            if (hasUse(state, dest)) {
                return false; }
        }
        return true;
    }

    bool neverUseAfter(const IR::ParserState* state, cstring src) const {
        bool never_use = true;
        VisitFollowingStates visit_following(state, refMap);
        visit_following.run([&] (const IR::ParserState* s) {
            if (s != state && hasUse(s, src)) {
                never_use = false; }
        });
        return never_use;
    }

    void dfs(const IR::ParserState* state) {
        // Do check first so that loop case is covered.
        forAllMatching<IR::AssignmentStatement>(
                state, [&] (const IR::AssignmentStatement* assign) {
                    cstring dest, src;
                    std::tie(dest, src) = getAssignNames(assign);
                    // copy out to parameter, where src is the local variable, and dest is the
                    // out parameter.
                    if (parameters.count(dest)) {
                        if (neverUseBefore(stack, dest, src) && neverUseAfter(state, src)) {
                            rewrite_with.insert({src, dest});
                            LOG1("Possible replace, src " << src << " by " << dest);
                        } else {
                            cannot_rewrite_with.insert({src, dest});
                            LOG1("Do not replace, , src " << src << " by " << dest);
                            LOG3("Reason: neverUseBefore = " << neverUseBefore(stack, dest, src));
                            LOG3("Reason, neverUseAfter = " << neverUseAfter(state, src));
                        }
                    } else {
                        LOG3("Ignore assignment to non-parameter: " << dest);
                    }
                });

        if (in_stack.count(state)) {
            return; }

        Visiting(state);

        for (const auto* next : getNextStates(refMap, state)) {
            dfs(next); }

        Leaving(state);
    }

    bool preorder(const IR::P4Parser* parser) {
        // parameters
        for (const auto* para : parser->type->applyParams->parameters) {
            LOG3("Found parameter, para->name = " << para->name);
            parameters.insert(para->name.name);
        }

        auto start = parser->states.getDeclaration<IR::ParserState>("start");
        BUG_CHECK(start, "parser does not have start state: %1%", parser);

        dfs(start);
        return true;
    }

    void Visiting(const IR::ParserState* state) {
        stack.push_back(state);
        in_stack.insert(state);
    }

    void Leaving(const IR::ParserState* state) {
        stack.pop_back();
        in_stack.erase(state);
    }

    P4::ReferenceMap *refMap;
    std::set<cstring> parameters;
    std::vector<const IR::ParserState*> stack;
    std::set<const IR::ParserState*> in_stack;
    std::set<std::pair<cstring, cstring>> rewrite_with;
    std::set<std::pair<cstring, cstring>> cannot_rewrite_with;

 public:
    explicit CollectInlineSubparser(P4::ReferenceMap *refMap)
        : refMap(refMap) { }

    std::set<std::pair<cstring, cstring>> getReplaceWith() const {
        std::set<std::pair<cstring, cstring>> rst = rewrite_with;
        rst.erase(cannot_rewrite_with.begin(), cannot_rewrite_with.end());
        return rst;
    }
};

class ReplaceSubparserPath : public Modifier {
    profile_t init_apply(const IR::Node* root) override {
        replace_by.clear();
        for (const auto& kv : inline_rst.getReplaceWith()) {
            replace_by.insert(kv);
        }
        return Modifier::init_apply(root);
    }

    bool preorder(IR::PathExpression* path) override {
        auto* ps = findContext<IR::ParserState>();
        if (!ps) {
            return true; }
        cstring name = path->path->name.name;
        if (replace_by.count(name)) {
            path->path = new IR::Path(IR::ID(replace_by[name]));
        }
        return true;
    }

    const CollectInlineSubparser& inline_rst;
    std::map<cstring, cstring> replace_by;

 public:
    explicit ReplaceSubparserPath(const CollectInlineSubparser& inline_rst)
        : inline_rst(inline_rst) { }
};

}  // namespace

InlineSubparserParameter::InlineSubparserParameter(P4::ReferenceMap *refMap) {
    auto* inline_subparser = new CollectInlineSubparser(refMap);
    addPasses({
        new P4::ResolveReferences(refMap),
        inline_subparser,
        new ReplaceSubparserPath(*inline_subparser)
    });
}
