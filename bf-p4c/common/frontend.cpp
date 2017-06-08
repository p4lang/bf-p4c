#include "frontend.h"

const IR::Type_Extern *Tofino::ExternConverter::convertExternType(
        const IR::Type_Extern *ext, cstring name) {
    if (ext->name == "stateful_alu") {
        if (!has_stateful_alu) {
            has_stateful_alu = true;
            structure->include("tofino/stateful_alu.p4");
        }
        name = "stateful_alu_14";
    } else {
        warning("Unrecognized extern_type %s", ext); }
    return P4V1::ExternConverter::convertExternType(ext, name);
}

const IR::Declaration_Instance *Tofino::ExternConverter::convertExternInstance(
        const IR::Declaration_Instance *ext, cstring name) {
    auto *rv = ext->clone();
    auto *et = rv->type->to<IR::Type_Extern>();
    BUG_CHECK(et, "Extern %s is not extern type, but %s", ext, ext->type);
    if (structure->extern_remap.count(et))
        et = structure->extern_remap.at(et);
    rv->name = name;
    rv->type = new IR::Type_Name(new IR::Path(structure->extern_types.get(et)));
    return rv->apply(P4V1::TypeConverter(structure))->to<IR::Declaration_Instance>();
}

