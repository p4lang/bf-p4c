#ifndef TOFINO_PHV_TRIVIAL_ALLOC_H_
#define TOFINO_PHV_TRIVIAL_ALLOC_H_

#include <map>
#include <vector>
#include "ir/ir.h"
#include "phv_fields.h"

namespace PHV {

struct ContainerAllocation;
struct FieldGroup;

/**
 * A PHV allocator which assigns fields to containers using a greedy algorithm.
 *
 * TrivialAlloc doesn't support more sophisticated PHV allocation techniques
 * like overlaying multiple fields into the same container, so it's
 * inappropriate for use with large programs.
 */
class TrivialAlloc final : public Inspector {
 public:
    explicit TrivialAlloc(PhvInfo &p) : phv(p) {}

 private:
    struct Regs;
    PhvInfo                     &phv;
    static bool tagalong_full(int size, Regs *use);
    static void alloc_pov(PhvInfo::Field *i, PhvInfo::Field *pov);
    void do_alloc(PhvInfo::Field *, Regs *, Regs *, int = 0);
    bool preorder(const IR::Tofino::Pipe *p) override;
    void end_apply(const IR::Node *) override { phv.set_done(); }
};

/**
 * A PHV allocator that allows you to manually allocate some fields. Any fields
 * which aren't assigned to a container manually are allocated using a
 * TrivialAlloc-like greedy allocator.
 *
 * This allocator is designed for testing and experimentation. It works against
 * a simplified model of the Tofino hardware with infinite PHV containers, and
 * by default it doesn't enforce hardware constraints on the allocations you
 * request, so you can easily construct an allocation that doesn't make sense or
 * is unrealizable on hardware.
 */
class ManualAlloc final : public Inspector {
 public:
   /**
    * A name that uniquely identifies a field. This is derived from the P4 field
    * name, but it will generally have been transformed by earlier compiler
    * passes - for example, CreateThreadLocalInstances separates the ingress and
    * egress version of a field and adds `ingress::` and `egress::` prefixes to
    * differentiate them.
    */
    using FieldId = cstring;

    /**
     * An allocation for a field. This consists of a sequence of slices, each
     * of which maps a contiguous sequence of N bits in the field to a sequence
     * of N bits in a PHV container.
     *
     * This structure is analogous to PhvInfo::Field::alloc_slice.
     */
    struct Slice {
        PHV::Container container;
        int field_bit;
        int container_bit;
        int width;
    };
    using Allocation = std::vector<Slice>;

    /**
     * A map from fields to allocations.
     *
     * ManualAlloc treats each PHV container as either entirely manually
     * allocated, or entirely automatic. If you manually assign any bits in a
     * PHV container, you must either assign all of them or allow some bits to
     * go unused. The same rule applies to fields, and when multiple fields must
     * be grouped into the same container because they aren't byte-aligned, the
     * rule applies to the entire group.
     */
    using AssignmentMap = std::map<FieldId, Allocation>;

    /**
     * Creates a PHV allocator which assigns containers to the fields in @phv.
     * If a field appears in @assignments, the provided allocation is used for
     * that field. Other fields are allocated greedily.
     */
    explicit ManualAlloc(PhvInfo& phv, const AssignmentMap& assignments = { })
        : phv(phv), assignments(assignments), checkAssignments(false) { }
    ManualAlloc(PhvInfo& phv, AssignmentMap&& assignments)
        : phv(phv), assignments(assignments), checkAssignments(false) { }

    /**
     * As above, but if @checked is true, the manual allocations in @assignments
     * are subject to checks for basic hardware constraints - for example, the
     * same container may not be assigned to both threads. These checks are
     * normally bypassed for manual allocations, but it's helpful to enable them
     * when testing ManualAlloc itself.
     */
    ManualAlloc(PhvInfo& phv, bool checked, const AssignmentMap& assignments = { })
        : phv(phv), assignments(assignments), checkAssignments(checked) { }
    ManualAlloc(PhvInfo& phv, bool checked, AssignmentMap&& assignments)
        : phv(phv), assignments(assignments), checkAssignments(checked) { }

 private:
    void allocateFieldGroup(const FieldGroup& group, ContainerAllocation& alloc);
    bool preorder(const IR::Tofino::Pipe*) override;
    void end_apply(const IR::Node*) override;

    PhvInfo& phv;
    AssignmentMap assignments;
    const bool checkAssignments;
};

}  // namespace PHV


#endif /* TOFINO_PHV_TRIVIAL_ALLOC_H_ */
