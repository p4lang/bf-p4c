#include "bf-p4c/midend/check_unsupported.h"
#include "frontends/p4/methodInstance.h"

namespace BFN {

bool CheckUnsupported::preorder(const IR::Type_StructLike* header) {
    for (auto f : header->fields)
        if (f->type->is<IR::Type_Varbits>())
            P4C_UNIMPLEMENTED("%1%: the varbit type is not yet supported in the backend", f);
    return false;
}

bool CheckUnsupported::preorder(const IR::MethodCallExpression* method) {
    // check for a call on packet_in extract with varbits
    auto mi = P4::MethodInstance::resolve(method, _refMap, _typeMap, true);
    const P4::ExternMethod *em = nullptr;
    if (mi && (em = mi->to<P4::ExternMethod>())) {
        auto externName = em->actualExternType->name;
        auto methodName = method->method->to<IR::Member>()->member.name;
        if (methodName == "extract" && externName == "packet_in" && method->arguments->size() == 2)
            P4C_UNIMPLEMENTED("%1%: extract with a variable number of bits is not yet supported "
                              "in the backend", method->method);
    }
    return false;
}

}  // namespace BFN
