#include "split_phv_use.h"

#include <boost/range/adaptor/reversed.hpp>

#include <vector>

#include "bf-p4c/common/slice.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/phv/phv_fields.h"

namespace {

const IR::Node* splitExtract(const IR::BFN::Extract* extract,
                             const bitrange& extractBits,
                             const std::vector<bitrange>& slices) {
    if (slices.empty()) return extract;
    if (slices.size() == 1 && slices[0] == extractBits) {
        LOG3("SplitPhvUse: no need to split: " << extract);
        return extract;
    }

    auto rv = new IR::Vector<IR::BFN::ParserPrimitive>();

    // For extracts that don't come from the input buffer, all we need to do is
    // split up the portion of the destination we're writing to.
    if (!extract->is<IR::BFN::ExtractBuffer>()) {
        for (auto slice : boost::adaptors::reverse(slices)) {
            auto* clone = extract->clone();
            clone->dest = MakeSlice(extract->dest, slice.lo, slice.hi);
            LOG3("SplitPhvUse: creating slice " << clone);
            rv->push_back(clone);
        }
        return rv;
    }

    // If we're extracting from the input buffer, we also need to fix up the
    // range of bits we're reading from.
    for (auto slice : boost::adaptors::reverse(slices)) {
        auto* clone = extract->to<IR::BFN::ExtractBuffer>()->clone();
        clone->dest = MakeSlice(extract->dest, slice.lo, slice.hi);
        LOG3("SplitPhvUse: rewriting slice " << slice << " of: " << clone);
        const auto destWidth = extract->dest->type->width_bits();
        clone->range = clone->range.shiftedByBits(destWidth - (slice.hi + 1))
                                   .resizedToBits(slice.size());
        LOG3("SplitPhvUse: rewrote to: " << clone);
        rv->push_back(clone);
    }
    return rv;
}

const IR::Node* splitEmit(const IR::BFN::Emit* emit,
                          const bitrange& emitBits,
                          const std::vector<bitrange>& slices) {
    if (slices.empty()) return emit;
    if (slices.size() == 1 && slices[0] == emitBits) {
        LOG3("SplitPhvUse: no need to split: " << emit);
        return emit;
    }

    auto rv = new IR::Vector<IR::BFN::DeparserPrimitive>();
    for (auto slice : boost::adaptors::reverse(slices)) {
        auto* clone = emit->clone();
        clone->source = MakeSlice(emit->source, slice.lo, slice.hi);
        LOG3("SplitPhvUse: creating slice " << clone);
        rv->push_back(clone);
    }
    return rv;
}

const IR::Node* splitExpression(const IR::Expression* expr,
                                const bitrange& exprBits,
                                const std::vector<bitrange>& slices) {
    if (slices.empty()) return expr;
    if (slices.size() == 1 && slices[0] == exprBits) {
        LOG3("SplitPhvUse: no need to split: " << expr);
        return expr;
    }

    auto rv = new IR::Vector<IR::Expression>();
    for (auto slice : boost::adaptors::reverse(slices)) {
        auto clone = MakeSlice(expr->clone(), slice.lo, slice.hi);
        LOG3("SplitPhvUse: creating slice " << clone);
        rv->push_back(clone);
    }
    return rv;
}

}  // namespace

const IR::Node* SplitPhvUse::preorder(IR::BFN::Extract* extract) {
    prune();
    bitrange bits;
    auto* field = phv.field(extract->dest, &bits);
    if (!field) return extract;
    LOG3("SplitPhvUse: attempting to split " << *extract);
    std::vector<bitrange> slices;
    field->foreach_alloc(bits, [&](const PhvInfo::Field::alloc_slice& alloc) {
        slices.push_back(alloc.field_bits());
    });
    return splitExtract(extract, bits, slices);
}

const IR::Node* SplitPhvUse::preorder(IR::BFN::Emit* emit) {
    prune();
    bitrange bits;
    auto* field = phv.field(emit->source, &bits);
    if (!field) return emit;
    std::vector<bitrange> slices;
    field->foreach_alloc(bits, [&](const PhvInfo::Field::alloc_slice& alloc) {
        slices.push_back(alloc.field_bits());
    });
    return splitEmit(emit, bits, slices);
}

const IR::Node* SplitPhvUse::preorder(IR::BFN::EmitChecksum* emit) {
    prune();

    // A checksum uses a list of fields as input, and we need to split each
    // field individually.
    IR::Vector<IR::Expression> sources;
    for (auto* source : emit->sources) {
        bitrange bits;
        auto* field = phv.field(source, &bits);
        if (!field) {
            sources.push_back(source);
            continue;
        }

        std::vector<bitrange> slices;
        field->foreach_alloc(bits, [&](const PhvInfo::Field::alloc_slice& alloc) {
            slices.push_back(alloc.field_bits());
        });

        sources.pushBackOrAppend(splitExpression(source, bits, slices));
    }

    emit->sources = sources;
    return emit;
}

const IR::Node* SplitPhvUse::preorder(IR::Expression* expr) {
    bitrange bits;
    auto* field = phv.field(expr, &bits);
    if (!field) return expr;

    // Prune after we know we have a field, so that if not, we still descend
    // into subexpressions. (That'll potentially trigger the warning below, but
    // we want to know about it.)
    prune();

    std::vector<bitrange> slices;
    field->foreach_alloc(bits, [&](const PhvInfo::Field::alloc_slice& alloc) {
        slices.push_back(alloc.field_bits());
    });

    auto* split = splitExpression(expr, bits, slices);
    if (split != expr && getContext()->node->is<IR::Expression>()) {
        // FIXME -- trying to split a child of an expression -- need to be splitting
        // that expression, or issuing an error about that expression earlier.
        WARNING("Want to split child expression " << *expr << " but can't");
        return expr;
    }
    return split;
}
