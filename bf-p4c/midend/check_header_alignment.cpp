#include "bf-p4c/midend/check_header_alignment.h"
#include "bf-p4c/device.h"
#include "frontends/p4/typeMap.h"

#include "ir/ir.h"

namespace BFN {

bool CheckHeaderAlignment::findFlexibleAnnotation(const IR::Type_StructLike* header)  {
    for (auto f : header->fields) {
        if (f->type->is<IR::Type_Bits>() || f->type->is<IR::Type_Varbits>())
            continue;
        auto canonicalType = typeMap->getTypeType(f->type, true);
        if (auto st = canonicalType->to<IR::Type_StructLike>()) {
            auto anno = st->getAnnotation("flexible");
            if (anno != nullptr)
                return true;
            if (findFlexibleAnnotation(st))
                return true; } }
    return false;
}

bool CheckHeaderAlignment::preorder(const IR::Type_Header* header) {
    auto canonicalType = typeMap->getTypeType(header, true);
    auto found = findFlexibleAnnotation(header);
    ERROR_CHECK(canonicalType->width_bits() % 8 == 0 || found,
                "%1% requires byte-aligned headers, but header %2% is not "
                "byte-aligned (has %3% bits)", Device::name(), header->name,
                canonicalType->width_bits());
    return false;
}

}  // namespace BFN
