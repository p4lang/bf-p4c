#ifndef BF_P4C_PHV_PHV_PARDE_MAU_USE_H_
#define BF_P4C_PHV_PHV_PARDE_MAU_USE_H_

#include "ir/ir.h"
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/ir/thread_visitor.h"
#include "bf-p4c/ir/tofino_write_context.h"
#include "bf-p4c/phv/phv.h"

namespace PHV {
class Field;
}  // namespace PHV

class PhvInfo;

class Phv_Parde_Mau_Use : public Inspector, public TofinoWriteContext {
    /// Fields written in the MAU pipeline.
    bitvec      written_i;

    /// Fields used in at least one ALU instruction.
    bitvec      used_alu_i;

    /// Fields extracted in the parser.
    bitvec      extracted_i[3];

    /// Used to associate $stkvalid and $valid fields for header stacks.
    BFN::HeaderStackInfo* stacks;

    /// Handy enum for indexing use_i below.
    enum { PARDE = 0, MAU = 1 };

 public:
    bitvec      use_i[2][3];
    /*                |  ^- gress                 */
    /*                0 == use in parser/deparser */
    /*                1 == use in mau             */

    bitvec      deparser_i[3];
    /*                |    ^- gress               */
    /*                 == use in deparser         */

    explicit Phv_Parde_Mau_Use(const PhvInfo &p) : phv(p) { }

    /// @returns true if @f is read or written anywhere in the pipeline
    /// or if @f is marked bridged.
    bool is_referenced(const PHV::Field *f) const;

    /// @returns true if @f is used in the deparser.
    bool is_deparsed(const PHV::Field *f) const;

    /// @returns true if @f is used (read or written) in the MAU pipeline.
    bool is_used_mau(const PHV::Field *f) const;

    /// @returns true if @f is written in the MAU pipeline.
    bool is_written_mau(const PHV::Field *f) const;

    /// @returns true if @f is used in an ALU instruction.
    bool is_used_alu(const PHV::Field *f) const;

    /// @returns true if @f is used in the parser or deparser.
    bool is_used_parde(const PHV::Field *f) const;

    /// @returns true if @f is extracted in the (ingress or egress) parser.
    bool is_extracted(const PHV::Field *f, boost::optional<gress_t> gress = boost::none) const;

 protected:
    const PhvInfo &phv;
    gress_t       thread;
    bool          in_mau;
    bool          in_dep;

 private:
    profile_t init_apply(const IR::Node *) override;
    bool preorder(const IR::BFN::Parser *) override;
    bool preorder(const IR::BFN::Extract *) override;
    bool preorder(const IR::BFN::Deparser *) override;
    bool preorder(const IR::MAU::TableSeq *) override;
    bool preorder(const IR::Expression *) override;

    bool preorder(const IR::BFN::Pipe* pipe) override {
        stacks = pipe->headerStackInfo;
        BUG_CHECK(stacks, "No header stack info.  Running PhvUse before CollectHeaderStackInfo?");
        return true;
    }
};

/// Consider additional cases specific to Phv Allocation, e.g., treat
/// egress_port and digests as used in MAU as they can't go in TPHV.
class PhvUse : public Phv_Parde_Mau_Use {
 public:
    explicit PhvUse(const PhvInfo &p) : Phv_Parde_Mau_Use(p) { }

 private:
    bool preorder(const IR::BFN::Deparser *d) override;
    bool preorder(const IR::BFN::DeparserParameter *param) override;
    void postorder(const IR::BFN::DeparserParameter *param) override;
    bool preorder(const IR::BFN::Digest *digest) override;
    void postorder(const IR::BFN::Digest *digest) override;
};

#endif /* BF_P4C_PHV_PHV_PARDE_MAU_USE_H_ */
