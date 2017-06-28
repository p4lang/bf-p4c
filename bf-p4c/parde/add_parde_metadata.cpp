#include "add_parde_metadata.h"
#include "lib/exceptions.h"

IR::Member *gen_fieldref(const IR::HeaderOrMetadata *hdr, cstring field) {
    const IR::Type *ftype = nullptr;
    auto f = hdr->type->getField(field);
    if (f != nullptr)
        ftype = f->type;
    else
        BUG("No field %s in %s", field, hdr->name);
    return new IR::Member(ftype, new IR::ConcreteHeaderRef(hdr), field);
}

bool AddMetadataShims::preorder(IR::Tofino::Parser *parser) {
    if (parser->gress == INGRESS) {
        auto *meta = findContext<IR::Tofino::Pipe>()->metadata["standard_metadata"];
        if (!meta) return false;
        parser->start = new IR::Tofino::ParserState(
            "$ingress_metadata_shim", parser->gress, {}, {
            new IR::Tofino::ParserMatch(match_t(), 16, {
                new IR::Primitive("extract", gen_fieldref(meta, "ingress_port")) },
                parser->start) });
    } else if (parser->gress == EGRESS) {
        auto *meta = findContext<IR::Tofino::Pipe>()->metadata["standard_metadata"];
        if (!meta) return false;
        parser->start = new IR::Tofino::ParserState(
            "$egress_metadata_shim", parser->gress, {}, {
            new IR::Tofino::ParserMatch(match_t(), 2, {
                new IR::Primitive("extract", gen_fieldref(meta, "egress_port")) },
                parser->start) });
    }
    return false;
}

bool AddMetadataShims::preorder(IR::Tofino::Deparser *d) {
    if (d->gress == INGRESS) {
        auto *meta = findContext<IR::Tofino::Pipe>()->metadata["standard_metadata"];
        if (!meta) return false;
        d->egress_port =  gen_fieldref(meta, "egress_spec");
    } else if (d->gress == EGRESS) {
        // egress_port is read-only
        auto *meta = findContext<IR::Tofino::Pipe>()->metadata["standard_metadata"];
        if (!meta) return false;
        d->egress_port =  gen_fieldref(meta, "egress_port");
    }
    return false;
}
