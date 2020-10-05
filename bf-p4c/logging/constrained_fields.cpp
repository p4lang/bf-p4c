#include "constrained_fields.h"

/* ConstrainedSlice */

ConstrainedSlice::ConstrainedSlice(const ConstrainedField &parent, le_bitrange range)
    : parent(parent), range(range) {
    using Slice = Logging::Phv_Schema_Logger::Slice;
    using FieldSlice = Logging::Phv_Schema_Logger::FieldSlice;

    logger = new Constraint(
        new FieldSlice(std::string(stripThreadPrefix(parent.getName())),
            new Slice(range.lo, range.hi)));
}

void ConstrainedSlice::setAlignment(const Constraints::AlignmentConstraint &alignment) {
    ConstrainedSlice::alignment = alignment;
}

bool ConstrainedSlice::operator<(const ConstrainedSlice &other) const {
    if (parent.getName() != other.parent.getName())
        return parent.getName() < other.parent.getName();
    return range < other.range;
}

bool ConstrainedSlice::operator==(const ConstrainedSlice &other) const {
    return parent.getName() == other.parent.getName() && range == other.range;
}

/* ConstrainedField */

ConstrainedField::ConstrainedField(const cstring &name) : name(name) {
    logger = new Constraint(nullptr);
}

void ConstrainedField::setSolitary(const Constraints::SolitaryConstraint &solitary) {
    ConstrainedField::solitary = solitary;
}

void ConstrainedField::setAlignment(const Constraints::AlignmentConstraint &alignment) {
    ConstrainedField::alignment = alignment;
}

void ConstrainedField::setDigest(const Constraints::DigestConstraint &digest) {
    ConstrainedField::digest = digest;
}

void ConstrainedField::setBottomBits(bool b) {
    deparsedBottomBits = b;
}

void ConstrainedField::addSlice(ConstrainedSlice &slice) {
    slices.insert(slice);
}

/* ConstrainedFieldMap */

ConstrainedFieldMap ConstrainedFieldMapBuilder::buildMap(const PhvInfo &phv,
                                                    const std::list<PHV::SuperCluster*> &groups) {
    ConstrainedFieldMap result;

    for (auto &f : phv) {
        result[f.name] = ConstrainedField(f.name);

        // Extract constraints for a field
        result[f.name].setSolitary(f.getSolitaryConstraint());
        result[f.name].setAlignment(f.getAlignmentConstraint());
        result[f.name].setDigest(f.getDigestConstraint());
        result[f.name].setBottomBits(f.deparsed_bottom_bits());
    }

    // Extract slices based on clustering
    for (auto sc : groups) {
        sc->forall_fieldslices([&] (const PHV::FieldSlice &slice) {
            BUG_CHECK(result.find(slice.field()->name) != result.end(),
                "Field is not present in PhvInfo, but is in supercluster.");
            auto &field = result.at(slice.field()->name);

            // Extract constraints for a slice
            ConstrainedSlice csl(field, slice.range());
            if (slice.alignment()) {
                Constraints::AlignmentConstraint alignment;
                alignment.addConstraint(
                    field.getAlignment().getReason(),
                    slice.alignment().get().align);
                csl.setAlignment(alignment);
            }

            field.addSlice(csl);
        });
    }

    return result;
}
