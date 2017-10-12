#ifndef BF_P4C_PHV_CONSTRAINTS_H_
#define BF_P4C_PHV_CONSTRAINTS_H_

#include "field_alignment.h"

namespace PHV {
class Field;
}  // namespace PHV

class Constraint {
 public:
    class True : public Constraint { };
    class False : public Constraint { };

    /// Conjunction.
    class And : public Constraint {
     public:
        const Constraint left;
        const Constraint right;
        And(const Constraint left, const Constraint right) : left(left), right(right) { }
    };

    /// Disjunction.
    class Or : public Constraint {
     public:
        const Constraint left;
        const Constraint right;
        Or(const Constraint left, const Constraint right) : left(left), right(right) { }
    };

    /// Negation.
    class Not : public Constraint {
     public:
        const Constraint operand;
        explicit Not(const Constraint operand) : operand(operand) { }
    };

    /// Implication.
    class Implies : public Constraint {
     public:
        const Constraint left;
        const Constraint right;
        Implies(const Constraint left, const Constraint right) : left(left), right(right) { }
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
    class Adjacent : public Constraint {
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
    class Align : public Constraint {
     public:
        const PHV::Field* f;
        const FieldAlignment alignment;
        Align(const PHV::Field* f, const FieldAlignment alignment)
        : f(f), alignment(alignment) { }
    };

    /** @f is placed at @alignment from the start of the a byte-aligned offset
     * in the container.
     */
    class AlignMod8 : public Constraint {
     public:
        const PHV::Field* f;
        const FieldAlignment alignment;
        AlignMod8(const PHV::Field* f, const FieldAlignment alignment)
        : f(f), alignment(alignment) { }
    };


    /** @f1 and @f2 are placed at the same offset in their respective
     * containers, whatever offset that may be.
     */
    class AlignEq : public Constraint {
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
    class SameContainer : public Constraint {
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
    class Isolate : public Constraint {
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
    class NoSlice : public Constraint {
        const PHV::Field* f;
     public:
        explicit NoSlice(const PHV::Field* f) : f(f) { }
    };
};

#endif /* BF_P4C_PHV_CONSTRAINTS_H_ */
