#ifndef BF_P4C_PHV_PHV_PARDE_MAU_USE_H_
#define BF_P4C_PHV_PHV_PARDE_MAU_USE_H_

#include "ir/ir.h"
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

 public:
    bitvec      use_i[2][2];
    /*                |  ^- gress                 */
    /*                0 == use in parser/deparser */
    /*                1 == use in mau             */
    bitvec      deparser_i[2];
    /*                |    ^- gress               */
    /*                 == use in deparser         */
    //
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

    /// @returns true if @f is used in the parser or deparser.
    bool is_used_parde(const PHV::Field *f) const;

 protected:
    const PhvInfo &phv;
    gress_t       thread;
    bool          in_mau;
    bool          in_dep;
    //
 private:
    profile_t init_apply(const IR::Node *root) override;
    bool preorder(const IR::BFN::Parser *p) override;
    bool preorder(const IR::BFN::Deparser *d) override;
    bool preorder(const IR::MAU::TableSeq *) override;
    bool preorder(const IR::Expression *e) override;
};  // Phv_Parde_Mau_Use

//
// consider additional cases specific to Phv Allocation
// e.g., treat egress_port and digests as in mau as they can't go in TPHV
//
class PhvUse : public Phv_Parde_Mau_Use {
 public:
    explicit PhvUse(const PhvInfo &p) : Phv_Parde_Mau_Use(p) { }
    //
 private:
    bool preorder(const IR::BFN::Deparser *d) override;
    bool preorder(const IR::BFN::DeparserParameter *param) override;
    void postorder(const IR::BFN::DeparserParameter *param) override;
    bool preorder(const IR::BFN::Digest *digest) override;
    void postorder(const IR::BFN::Digest *digest) override;
};
//
//
#endif /* BF_P4C_PHV_PHV_PARDE_MAU_USE_H_ */
