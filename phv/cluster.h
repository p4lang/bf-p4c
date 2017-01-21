#ifndef _TOFINO_PHV_CLUSTER_H_
#define _TOFINO_PHV_CLUSTER_H_

#include "phv.h"
#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/ordered_set.h"
#include "lib/range.h"
#include "tofino/ir/thread_visitor.h"
//
//
//***********************************************************************************
//
// class Cluster computes cluster sets of fields
// conditions:
// must perform cluster analysis after last &phv pass
// input:
// fields computed by PhvInfo phv
// these field pointers are not part of IR, they are calculated by &phv
// output:
// accumulated map<field*, pointer to cluster_set of field*>
//
//***********************************************************************************
//
//
class Cluster : public Inspector, P4WriteContext {
 public:
    class Uses;
 private:
    PhvInfo &phv_i;             // phv object referenced through constructor
    //
    ordered_map<const PhvInfo::Field *, ordered_set<const PhvInfo::Field *>*> dst_map_i;
                                // map of field to cluster it belongs
    ordered_set<const PhvInfo::Field *> lhs_unique_i;
                                // maintains unique cluster ptrs
    PhvInfo::Field *dst_i = nullptr;
                                // destination of current statement
    std::list<const PhvInfo::Field *> pov_fields_i;
                                // all pov fields
    std::list<const PhvInfo::Field *> pov_fields_not_in_cluster_i;
                                // pov fields not in cluster, need to be PHV allocated
    std::list<const PhvInfo::Field *> fields_no_use_mau_i;
                                // fields that are not used through mau pipeline
    Uses *uses_i;
    //
    bool preorder(const IR::Tofino::Pipe *) override;
    bool preorder(const IR::Member*) override;
    bool preorder(const IR::Operation_Unary*) override;
    bool preorder(const IR::Operation_Binary*) override;
    bool preorder(const IR::Operation_Ternary*) override;
    bool preorder(const IR::HeaderRef*) override;
    bool preorder(const IR::Primitive*) override;
    bool preorder(const IR::Operation*) override;
    bool preorder(const IR::Expression*) override;
    void postorder(const IR::Primitive*) override;
    void end_apply() override;
    //
    void insert_cluster(const PhvInfo::Field *, const PhvInfo::Field *);
    bool is_ccgf_member(const PhvInfo::Field *, const PhvInfo::Field *);
    void set_field_range(const IR::Expression&);
    void set_field_range(PhvInfo::Field *field);
    //
    void sanity_check_field_range(const std::string&);
    void sanity_check_clusters(const std::string&, const PhvInfo::Field *);
    void sanity_check_clusters_unique(const std::string&);
    void sanity_check_fields_use(const std::string&,
        std::set<const PhvInfo::Field *>,       // all fields
        std::set<const PhvInfo::Field *>,       // cluster fields
        std::set<const PhvInfo::Field *>,       // all - cluster
        std::set<const PhvInfo::Field *>,       // pov fields
        std::set<const PhvInfo::Field *>);      // no mau fields
    //
 public:
    //
    Cluster(PhvInfo &p);                       // NOLINT(runtime/explicit)
    //
    ordered_map<const PhvInfo::Field *, ordered_set<const PhvInfo::Field *>*>& dst_map() {
        return dst_map_i;
    }
    //
    std::list<const PhvInfo::Field *>& pov_fields()         { return pov_fields_i; }
    std::list<const PhvInfo::Field *>& pov_fields_not_in_cluster()
                                                            { return pov_fields_not_in_cluster_i; }
    //
    std::list<const PhvInfo::Field *>& fields_no_use_mau()  { return fields_no_use_mau_i; }
    void compute_fields_no_use_mau();
    //
    Uses& uses()  { return *uses_i; }
};
//
//
class Cluster::Uses : public Inspector {
 public:
    bitvec      use[2][2];
    /*              |  ^- gress                 */
    /*              0 == use in parser/deparser */
    /*              1 == use in mau             */
    explicit Uses(const PhvInfo &p) : phv(p) { }

 private:
    const PhvInfo       &phv;
    gress_t             thread;
    bool                in_mau;
    bool preorder(const IR::Tofino::Parser *p) {
        in_mau = false;
        thread = p->gress;
        revisit_visited();
        return true; }
    bool preorder(const IR::Tofino::Deparser *d) {
        thread = d->gress;
        in_mau = true;  // treat egress_port as in mau as it can't go in TPHV
        revisit_visited();
        visit(d->egress_port);
        in_mau = false;
        revisit_visited();
        d->emits.visit_children(*this);
        return false; }
    bool preorder(const IR::MAU::TableSeq *) {
        in_mau = true;
        revisit_visited();
        return true; }
    bool preorder(const IR::HeaderRef *hr) {
        if (auto head = phv.header(hr))
            use[in_mau][thread].setrange(head->first, head->second - head->first + 1);
        return false; }
    bool preorder(const IR::Expression *e) {
        if (auto info = phv.field(e)) {
            LOG3("use " << info->name << " in " << thread << (in_mau ? " mau" : ""));
            use[in_mau][thread][info->id] = true;
            return false; }
        return true; }
};
//
//
std::ostream &operator<<(std::ostream &, ordered_set<const PhvInfo::Field *>*);
std::ostream &operator<<(std::ostream &, std::vector<const PhvInfo::Field *>&);
std::ostream &operator<<(std::ostream &, Cluster &);
//
#endif /* _TOFINO_PHV_CLUSTER_H_ */
