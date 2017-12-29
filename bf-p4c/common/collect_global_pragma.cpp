#include "collect_global_pragma.h"
#include <algorithm>

const std::vector<cstring>*
CollectGlobalPragma::g_global_pragma_names = new std::vector<cstring>{
    "pa_mutually_exclusive"
};

bool CollectGlobalPragma::preorder(const IR::Annotation *annotation) {
    auto pragma_name = annotation->name.name;
    bool is_global_pragma = (std::find(g_global_pragma_names->begin(),
                                       g_global_pragma_names->end(), pragma_name)
                             != g_global_pragma_names->end());
    if (is_global_pragma) {
        global_pragmas_.push_back(annotation); }
    return false;
}
