#ifndef BF_P4C_PHV_TRIVIAL_ALLOC_H_
#define BF_P4C_PHV_TRIVIAL_ALLOC_H_

#include <map>
#include <vector>
#include "bf-p4c/phv/phv.h"
#include "ir/ir.h"

class PhvInfo;

namespace PHV {

struct ContainerAllocation;
struct FieldGroup;

/**
 * Trivial allocator that assumes an unlimited number of containers of all sizes,
 * and just allocates fields to successive "naturally" size containers, ignoring all
 * MAU constraints (just taking into account parser/deparser alignment constraints).
 * Designed to create a 'optimistic' allocation for table placement to use, prior to
 * a "real" allocation that will happen after table placment.
 */
class TrivialAlloc final : public Inspector {
 public:
    explicit TrivialAlloc(PhvInfo &p) : phv(p) {}

 private:
    struct Regs;
    PhvInfo             &phv;
    bitvec              aliasSrcs;
    void copy_alias(const PHV::Field &from, PHV::Field &to);
    void do_alloc(const FieldGroup&, Regs *);
    void postorder(const IR::BFN::AliasMember *alias) override;
    void postorder(const IR::BFN::AliasSlice *alias) override;
    bool preorder(const IR::BFN::Pipe *p) override;
    void postorder(const IR::BFN::Pipe *p) override;
    void end_apply(const IR::Node *) override;
};

}  // namespace PHV

#endif /* BF_P4C_PHV_TRIVIAL_ALLOC_H_ */
