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

std::tuple<bool, cstring, int, int> get_key_slice_info(const cstring &input) {
    std::string s(input);
    std::smatch match;
    std::regex sliceRegex(R"(\[([0-9]+):([0-9]+)\])");
    std::regex_search(s, match, sliceRegex);
    if (match.size() == 3) {
        int hi = std::atoi(match[1].str().c_str());
        int lo = std::atoi(match[2].str().c_str());
        return std::make_tuple(true, match.prefix().str(), hi, lo);
    }
    return std::make_tuple(false, ""_cs, -1, -1);
}

std::pair<cstring, cstring>
get_key_and_mask(const cstring &input) {
    std::string k(input);
    std::smatch match;
    std::regex maskRegex(R"([\s]*&[\s]*(0x[a-fA-F0-9]+))");
    std::regex_search(k, match, maskRegex);
    cstring key = input;
    cstring mask = ""_cs;
    if (match.size() >= 2) {
        key = match.prefix().str();
        mask = match[1].str();
    }
    return std::make_pair(key, mask);
}

const P4::IR::Vector<P4::IR::Expression>* getListExprComponents(const P4::IR::Node& node) {
    const P4::IR::Vector<P4::IR::Expression>* components;

    if (node.is<P4::IR::StructExpression>()) {
        auto freshVec = new P4::IR::Vector<P4::IR::Expression>();
        // sadly no .reserve() on P4::IR::Vector
        for (auto named : node.to<P4::IR::StructExpression>()->components) {
            freshVec->push_back(named->expression);
        }
        components = freshVec;
    } else if (node.is<P4::IR::ListExpression>()) {
        const P4::IR::ListExpression* sourceListExpr = node.to<P4::IR::ListExpression>();
        components = &(sourceListExpr->components);
    } else {
        BUG("getListExprComponents called with a non-list-like expression %s", P4::IR::dbp(&node));
    }

    return components;
}
void end_fatal_error() {
#if BAREFOOT_INTERNAL
    if (auto res = BFNContext::get().errorReporter().verify_checks();
            res ==  BfErrorReporter::CheckResult::SUCCESS) {
        std::clog << "An expected fatal error was raised, exiting.\n";
        std::exit(0);
    } else if (res == BfErrorReporter::CheckResult::FAILURE) {
        std::clog << "A diagnostic check failed in fatal error processing\n";
    }
#endif  /* BAREFOOT_INTERNAL */
    throw Util::CompilationError("Compilation failed!");
}

bool is_starter_pistol_table(const cstring &tableName) {
    return (tableName.startsWith("$") &&
        tableName.endsWith("_starter_pistol"));
}
