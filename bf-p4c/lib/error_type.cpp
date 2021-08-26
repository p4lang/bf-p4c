#include "error_type.h"

#include <vector>
#include <numeric>

#include "p4c/lib/exceptions.h"

void BFN::ErrorType::printWarningsHelp(std::ostream& out) {
    std::vector<int> warningTypes = {
        // p4c warnings types
        LEGACY_WARNING, WARN_FAILED, WARN_UNKNOWN, WARN_INVALID, WARN_UNSUPPORTED,
        WARN_DEPRECATED, WARN_UNINITIALIZED, WARN_UNUSED, WARN_MISSING, WARN_ORDERING,
        WARN_MISMATCH, WARN_OVERFLOW, WARN_IGNORE_PROPERTY, WARN_TYPE_INFERENCE,
        WARN_PARSER_TRANSITION, WARN_UNREACHABLE, WARN_SHADOWING, WARN_IGNORE,
        WARN_UNINITIALIZED_OUT_PARAM, WARN_UNINITIALIZED_USE,
        // bf-p4c warning types
        WARN_TABLE_PLACEMENT, WARN_PRAGMA_USE, WARN_SUBSTITUTION, WARN_PHV_ALLOCATION
    };

    auto &catalog = ErrorCatalog::getCatalog();

    BUG_CHECK(catalog.getName(WARN_UNINITIALIZED_USE + 1) == "--unknown--",
        "New warning types were added to p4c/lib/error_catalog.h "
        "that are not logged in printWarningsHelp()");
    BUG_CHECK(catalog.getName(WARN_PHV_ALLOCATION + 1) == "--unknown--",
        "New warning types were added to bf-p4c/lib/error_type.h "
        "that are not logged in printWarningsHelp()");

    out << "These are supported warning types for --Werror and --Wdisable: ";

    auto helptext = std::accumulate(warningTypes.begin() + 1, warningTypes.end(),
        std::string(catalog.getName(warningTypes.front()).c_str()),
        [&catalog] (const std::string &r, int type) -> std::string {
            return r + ", " + catalog.getName(type); });

    out << helptext << std::endl << std::endl;

    out << "You can provide one or more of these types as a "
           "comma separated list to --Werror/--Wdisable options." << std::endl << std::endl;
}
