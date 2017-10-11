#include "bf-p4c/common/check_header_alignment.h"
#include "bf-p4c/device.h"
#include "frontends/p4/typeMap.h"

#include "ir/ir.h"

namespace BFN {

bool CheckHeaderAlignment::preorder(const IR::Type_Header* header) {
    auto canonicalType = typeMap->getTypeType(header, true);
    ERROR_CHECK(canonicalType->width_bits() % 8 == 0,
                "%1% requires byte-aligned headers, but header %2% is not "
                "byte-aligned", Device::currentDevice(), header->name);
    return false;
}

}  // namespace BFN
