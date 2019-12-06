#include "bf-p4c/arch/helpers.h"

namespace BFN {

boost::optional<cstring> getExternTypeName(const P4::ExternMethod* extMethod) {
    boost::optional<cstring> name = boost::none;
    if (auto inst = extMethod->object->to<IR::Declaration_Instance>()) {
        if (auto tn = inst->type->to<IR::Type_Name>()) {
            name = tn->path->name;
        } else if (auto ts = inst->type->to<IR::Type_Specialized>()) {
            if (auto bt = ts->baseType->to<IR::Type_Name>()) {
                name = bt->path->name; } }
    } else if (auto param = extMethod->object->to<IR::Parameter>()) {
        if (auto tn = param->type->to<IR::Type_Name>()) {
            name = tn->path->name;
        } else if (auto te = param->type->to<IR::Type_Extern>()) {
            name = te->name;
        }
    }
    return name;
}


}  // namespace BFN
