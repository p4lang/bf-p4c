#include "add_parde_metadata.h"
#include "lib/exceptions.h"

IR::FieldRef *gen_fieldref(const IR::HeaderOrMetadata *hdr, cstring field) {
    const IR::Type *ftype = nullptr;
    for (auto f : *hdr->type->fields)
        if (f->name == field) {
            ftype = f->type;
            break; }
    if (!ftype)
        BUG("No field %s in %s", field, hdr->name);
    return new IR::FieldRef(ftype, new IR::ConcreteHeaderRef(hdr), field);
}

bool AddMetadataShims::preorder(IR::Tofino::Parser *parser) {
    auto *std_meta = findContext<IR::Tofino::Pipe>()->standard_metadata;
    if (!std_meta) return false;
    if (parser->gress == INGRESS) {
        parser->start = new IR::Tofino::ParserState(
            "$ingress_metadata_shim", {}, {
            new IR::Tofino::ParserMatch(match_t(), 16, {
                new IR::Primitive("extract", gen_fieldref(std_meta, "ingress_port")) },
                parser->start) });
    } else if (parser->gress == EGRESS) {
        parser->start = new IR::Tofino::ParserState(
            "$egress_metadata_shim", {}, {
            new IR::Tofino::ParserMatch(match_t(), 2, {
                new IR::Primitive("extract", gen_fieldref(std_meta, "egress_port")) },
                parser->start) });
    }
    return false;
}

bool AddMetadataShims::preorder(IR::Tofino::Deparser *d) {
    auto *std_meta = findContext<IR::Tofino::Pipe>()->standard_metadata;
    if (!std_meta) return false;
    if (d->gress == INGRESS)
        d->egress_port =  gen_fieldref(std_meta, "egress_spec");
    else if (d->gress == EGRESS)
        d->egress_port =  gen_fieldref(std_meta, "egress_port");
    return false;
}
