#ifndef BF_P4C_PHV_CONSTRAINTS_H_
#define BF_P4C_PHV_CONSTRAINTS_H_

#include <boost/optional.hpp>
#include "field_alignment.h"
#include "lib/ordered_map.h"

namespace PHV {
class Field;
}  // namespace PHV

namespace Constraint {

/** The parser can only extract chunks of the input buffer in fixed sizes, only
 * at byte-aligned offsets, and can only write into a given PHV container once
 * (later "writes" are actually bitwise-or).
 *
 * Hence, extracting one field may require extracting part of another.  An
 * ExtractorSchema describes the layout of extracted fields in the input
 * buffer and encodes the following constraints:
 *
 * 1. If more than one extracted field (or slice) is placed in the same
 *    container, then they must be aligned according to their relative
 *    placement in the input buffer.
 *
 * 2. Fields that are extracted but not in the same ExtractorSchema cannot be
 *    placed in the same container (unless overlaid).
 *
 * Note that this constraint does not prohibit an extracted field from being
 * packed with a non-extracted field.
 */
class ExtractorSchema {
    // Fields ordered by offset.
    std::vector<const PHV::Field*> fields_i;

    // Maps fields to their offset in the extraction schema.
    std::map<const PHV::Field*, unsigned> field_offsets_i;

 public:
    explicit ExtractorSchema(const std::vector<PHV::Field*>& fields) {
        // Insert into list, map.
        unsigned offset = 0;
        for (auto* f : fields) {
            fields_i.push_back(f);
            field_offsets_i[f] = offset;
            offset += f->size; }
    }

    /// @returns the number of fields in the schema.
    size_t size() const { return fields_i.size(); }

    using const_iterator = std::vector<const PHV::Field*>::const_iterator;
    const_iterator begin() const { return fields_i.begin(); }
    const_iterator end()   const { return fields_i.end(); }

    /// @returns @f's offset, or boost::none if @f is not in this ExtractorSchema.
    boost::optional<unsigned> offset(const PHV::Field* f) const {
        if (field_offsets_i.find(f) == field_offsets_i.end())
            return boost::none;
        return field_offsets_i.at(f);
    }
};

/** The deparser consumes entire containers: All container bits are deparsed,
 * in order, to the wire.  The DeparserSchema constraint captures fields that
 * can be deparsed together, along with the necessary ordering:
 *
 * 1. If more than one deparsed field (or slice) is placed in the same
 *    container, then they must be aligned according to their ordering.
 *    Additionally, all bits of the container must come from the same
 *    DeparserSchema.
 *
 * 2. If a deparsed field (or slice) is placed in a container without other
 *    fields in its deparser schema, then it must take up the entire container.
 *
 * XXX(cole): Things that induce deparser schemas: Deparsed headers, digests,
 * checksums.  Others?
 */
class DeparserSchema {
    // Fields ordered by offset.
    std::vector<const PHV::Field*> fields_i;

    // Maps fields to their offset in the extraction schema.
    std::map<const PHV::Field*, unsigned> field_offsets_i;

 public:
    explicit DeparserSchema(const std::vector<PHV::Field*>& fields) {
        // Insert into list, map.
        unsigned offset = 0;
        for (auto* f : fields) {
            fields_i.push_back(f);
            field_offsets_i[f] = offset;
            offset += f->size; }
    }

    /// @returns the number of fields in the schema.
    size_t size() const { return fields_i.size(); }

    using const_iterator = std::vector<const PHV::Field*>::const_iterator;
    const_iterator begin() const { return fields_i.begin(); }
    const_iterator end()   const { return fields_i.end(); }

    /// @returns @f's offset, or boost::none if @f is not in this ExtractorSchema.
    boost::optional<unsigned> offset(const PHV::Field* f) const {
        if (field_offsets_i.find(f) == field_offsets_i.end())
            return boost::none;
        return field_offsets_i.at(f);
    }
};




/** These classes are a thought exercise in developing a constraint language for
 * PHV allocation.  They are not currently used.
 */
class BaseConstraint { };

class True : public BaseConstraint { };
class False : public BaseConstraint { };

/// Conjunction.
class And : public BaseConstraint {
 public:
    const BaseConstraint left;
    const BaseConstraint right;
    And(const BaseConstraint left, const BaseConstraint right) : left(left), right(right) { }
};

/// Disjunction.
class Or : public BaseConstraint {
 public:
    const BaseConstraint left;
    const BaseConstraint right;
    Or(const BaseConstraint left, const BaseConstraint right) : left(left), right(right) { }
};

/// Negation.
class Not : public BaseConstraint {
 public:
    const BaseConstraint operand;
    explicit Not(const BaseConstraint operand) : operand(operand) { }
};

/// Implication.
class Implies : public BaseConstraint {
 public:
    const BaseConstraint left;
    const BaseConstraint right;
    Implies(const BaseConstraint left, const BaseConstraint right) : left(left), right(right) { }
};

/** All bits of @f1 are placed contiguously, followed immediately by all
 * bits of @f2.  Both fields may optionally span multiple containers.
 *
 * Examples of valid placements satisfying adjacent(f, g):
 *
 *   container   c1          c2          c3
 *             | ....ffff || ffffgggg || gggg.... |
 *             | ffffffff || gggggggg |
 *
 *               c4
 *             | ffffffffgggggggg |
 *
 *               c5
 *             | ........ffffffffgggggggg........ |
 *
 * where '.' implies bits in the container that may have any assignment.
 */
class Adjacent : public BaseConstraint {
 public:
    const PHV::Field* f1;
    const PHV::Field* f2;
    Adjacent(const PHV::Field* f1, const PHV::Field* f2) : f1(f1), f2(f2) { }
};

/** @f is placed at @alignment from the start of the container.
 *
 * XXX(for seth): Does @alignment specify the position of every bit in @f?
 * Does it also specify the size of the container?
 */
class Align : public BaseConstraint {
 public:
    const PHV::Field* f;
    const FieldAlignment alignment;
    Align(const PHV::Field* f, const FieldAlignment alignment)
    : f(f), alignment(alignment) { }
};

/** @f is placed at @alignment from the start of the a byte-aligned offset
 * in the container.
 */
class AlignMod8 : public BaseConstraint {
 public:
    const PHV::Field* f;
    const FieldAlignment alignment;
    AlignMod8(const PHV::Field* f, const FieldAlignment alignment)
    : f(f), alignment(alignment) { }
};


/** @f1 and @f2 are placed at the same offset in their respective
 * containers, whatever offset that may be.
 */
class AlignEq : public BaseConstraint {
 public:
    const PHV::Field* f1;
    const PHV::Field* f2;
    AlignEq(const PHV::Field* f1, const PHV::Field* f2) : f1(f1), f2(f2) { }
};

/** @f1 and @f2 are placed in the same container.
 *
 * Implies that if @f1 and @f2 are sliced, then they are the same size and
 * are sliced the same way, and corresponding slices are placed in the same
 * containers.
 *
 * For example, if @f1 is 16b and sliced into two 8b slices (f11, f12),
 * then @f2 must be sliced into two 8b slices (f21, f22), and
 * SameContainer(f11, f21) and SameContainer(f12, f22).
 *
 * XXX(cole): This constraint may be overly strong.  Need to revist as we
 * start using it.
 */
class SameContainer : public BaseConstraint {
 public:
    const PHV::Field* f1;
    const PHV::Field* f2;
    SameContainer(const PHV::Field* f1, const PHV::Field* f2) : f1(f1), f2(f2) { }
};

/** Fields in @fields are placed in the same containers, and no other fields
 * are placed in those containers.
 *
 * Examples of placements satisfying isolate(f, g):
 *
 * container   c1
 *           | ffffgggg |
 * 
 *             c2
 *           | ffff----gggg---- |
 *
 *             c3          c4
 *           | ff----gg || --ffgg-- |
 *
 * where '-' implies bits in the container left empty.
 */
class Isolate : public BaseConstraint {
 public:
    const ordered_set<const PHV::Field*> fields;
    explicit Isolate(const ordered_set<const PHV::Field*>& fields) : fields(fields) { }
};

/** @f is placed in a single container.
 *
 * Examples of placements satisfying NoSlice(f):
 *
 * container   c1
 *           | ffffffff |
 *
 *             c2
 *           | ........ffffffff |
 *
 *             c3
 *           | ....ffffffff.................... |
 *
 * where '.' implies bits in the container that may have any assignment.
 */
class NoSlice : public BaseConstraint {
    const PHV::Field* f;
 public:
    explicit NoSlice(const PHV::Field* f) : f(f) { }
};

}   // namespace Constraint

#endif /* BF_P4C_PHV_CONSTRAINTS_H_ */
