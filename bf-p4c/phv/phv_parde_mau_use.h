#ifndef BF_P4C_PHV_PHV_PARDE_MAU_USE_H_
#define BF_P4C_PHV_PHV_PARDE_MAU_USE_H_

#include "phv.h"
#include "phv_fields.h"
#include "ir/ir.h"
#include "bf-p4c/ir/thread_visitor.h"
#include "bf-p4c/ir/tofino_write_context.h"

//
class Phv_Parde_Mau_Use : public Inspector {
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
    //
    bool is_referenced(const PhvInfo::Field *f) const;
    bool is_deparsed(const PhvInfo::Field *f) const;
    bool is_used_mau(const PhvInfo::Field *f) const;
    bool is_used_parde(const PhvInfo::Field *f) const;
    //
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
};
//
//
#endif /* BF_P4C_PHV_PHV_PARDE_MAU_USE_H_ */
