#include "lib/log.h"
#include "bf-p4c/ir/tofino_write_context.h"

bool TofinoWriteContext::isWrite(bool root_value) {
    bool rv = P4WriteContext::isWrite(root_value);
    const IR::Node *current = getCurrentNode();
    const Context *ctxt = getContext();
    if (!ctxt || !ctxt->node || !current)
        return rv;

    const IR::Node* contextChild = current;
    while (ctxt->child_index == 0 &&
            (ctxt->node->is<IR::ArrayIndex>() ||
             ctxt->node->is<IR::HeaderStackItemRef>() ||
             ctxt->node->is<IR::Slice>() ||
             ctxt->node->is<IR::Member>())) {
        contextChild = ctxt->node;
        ctxt = ctxt->parent;
        if (!ctxt || !ctxt->node)
            return rv; }

    auto *salu = findContext<IR::MAU::SaluAction>();
    if (salu && current == salu->output_dst) {
        return true; }

    // The destination of an Extract is written to, but the other fields aren't.
    // This is just a roundabout way to check that we reached the Extract by
    // walking upwards via the destination and not via some other route.
    if (ctxt->node->is<IR::BFN::Extract>())
        return contextChild == ctxt->node->to<IR::BFN::Extract>()->dest;

    // TODO: Does C++ support monads?  The following if statements are nested
    // because C++ only supports declaring variables in if predicates if the
    // declaration is the only clause.
    if (auto *prim = ctxt->node->to<IR::MAU::TypedPrimitive>()) {
    if (prim->method_type) {
    if (auto *tm = prim->method_type->to<IR::Type_Method>()) {
    if (tm->parameters) {
    if (const IR::IndexedVector<IR::Parameter> *params = &tm->parameters->parameters) {
    if (ctxt->child_index >= 0) {
    if (static_cast<size_t>(ctxt->child_index) < params->size()) {
        const IR::Direction d = params->at(ctxt->child_index)->direction;
        if (d == IR::Direction::Out || d == IR::Direction::InOut)
            return true;
        else
            return false; } } } } } } }

    if (ctxt->node->to<IR::MAU::Instruction>())
        return ctxt->child_index == 0;

    return rv;
}

bool TofinoWriteContext::isRead(bool root_value) {
    bool rv = P4WriteContext::isRead(root_value);
    const IR::Node *current = getCurrentNode();
    const Context *ctxt = getContext();
    if (!ctxt || !ctxt->node || !current)
        return rv;
    while (ctxt->child_index == 0 &&
            (ctxt->node->is<IR::ArrayIndex>() ||
             ctxt->node->is<IR::HeaderStackItemRef>() ||
             ctxt->node->is<IR::Slice>() ||
             ctxt->node->is<IR::Member>())) {
        ctxt = ctxt->parent;
        if (!ctxt || !ctxt->node)
            return rv; }

    if (ctxt->child_index < 0)
        return rv;

    auto *salu = findContext<IR::MAU::SaluAction>();
    if (salu && current == salu->output_dst) {
        return false; }

    // XXX(seth): This treats both the destination and the source of the extract
    // as read. This is a hack intended to capture the fact that parser writes
    // OR the destination PHV container with its existing contents. Ideally,
    // we'd be more precise about this, and only treat the destination as read
    // if the container is marked multiwrite.
    if (ctxt->node->is<IR::BFN::Extract>())
        return true;

    // An Emit reads both the emitted field and the POV bit.
    if (ctxt->node->is<IR::BFN::Emit>())
        return true;

    // An EmitChecksum reads the POV bit and all checksummed fields.
    if (ctxt->node->is<IR::BFN::EmitChecksum>())
        return true;

    // A computed select reads its source.
    if (ctxt->node->is<IR::BFN::SelectComputed>())
        return true;

    // TODO: Does C++ support monads?  The following if statements are nested
    // because C++ only supports declaring variables in if predicates if the
    // declaration is the only clause.
    if (auto *prim = ctxt->node->to<IR::MAU::TypedPrimitive>()) {
    if (prim->method_type) {
    if (auto *tm = prim->method_type->to<IR::Type_Method>()) {
    if (tm->parameters) {
    if (const IR::IndexedVector<IR::Parameter> *params = &tm->parameters->parameters) {
    if ((size_t)(ctxt->child_index) < params->size()) {
        const IR::Direction d = params->at(ctxt->child_index)->direction;
        if (d == IR::Direction::In || d == IR::Direction::InOut)
            return true;
        else
            return false; } } } } } }

    if (ctxt->node->is<IR::MAU::Instruction>())
        return ctxt->child_index > 0;

    if (ctxt->node->is<IR::MAU::InputXBarRead>())
        return true;

    if (auto *hashdist = ctxt->node->to<IR::MAU::HashDist>()) {
        if (current == hashdist->field_list)
            return true;
        if (auto *fl = hashdist->field_list->to<IR::FieldList>()) {
            for (auto *f : fl->fields) {
                if (current == f)
                    return true; } } }

    return rv;
}
