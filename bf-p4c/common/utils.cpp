#include <regex>

#include "utils.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/device.h"

bool ghost_only_on_other_pipes(int pipe_id) {
    if (pipe_id < 0) return false;  // invalid pipe id

    auto options = BackendOptions();
    if (!Device::hasGhostThread()) return false;
    if (options.ghost_pipes == 0) return false;

    if ((options.ghost_pipes & (0x1 << pipe_id)) == 0) {
       return true;
    }
    return false;
}

std::pair<cstring, cstring>
get_key_and_mask(const cstring &input) {
    std::string k(input);
    std::smatch match;
    std::regex maskRegex(R"([\s]*&[\s]*(0x[a-fA-F0-9]+))");
    std::regex_search(k, match, maskRegex);
    cstring key = input;
    cstring mask = "";
    if (match.size() >= 2) {
        key = match.prefix().str();
        mask = match[1].str();
    }
    return std::make_pair(key, mask);
}

const IR::Vector<IR::Expression>* getListExprComponents(const IR::Node& node) {
    const IR::Vector<IR::Expression>* components;

    if (node.is<IR::StructExpression>()) {
        auto freshVec = new IR::Vector<IR::Expression>();
        // sadly no .reserve() on IR::Vector
        for (auto named : node.to<IR::StructExpression>()->components) {
            freshVec->push_back(named->expression);
        }
        components = freshVec;
    } else if (node.is<IR::ListExpression>()) {
        const IR::ListExpression* sourceListExpr = node.to<IR::ListExpression>();
        components = &(sourceListExpr->components);
    } else {
        BUG("getListExprComponents called with a non-list-like expression %s", IR::dbp(&node));
    }

    return components;
}
