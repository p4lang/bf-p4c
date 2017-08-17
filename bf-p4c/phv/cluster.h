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
#include "tofino/ir/tofino_write_context.h"

/** @brief Builds "clusters" of PHV fields that must be placed in the same
 * group.
 *
 * Produces a map from each PhvInfo.Field to its "cluster" set.  Two fields are
 * placed in the same cluster if any of the following are true:
 *
 *  - they are part of same instruction (as operands and/or assignment
 *  destination)
 *  - they are part of two CCGFs that are in the same group
 *
 * Perform cluster analysis after last &phv pass
 * fields computed by PhvInfo phv, these field pointers are not part of IR
 *
 * This pass also fills in the following PhvInfo::Field fields:
 *  - mau_write
 *  - phv_use_lo
 *  - phv_use_hi
 *  - ccgf
 *  - ccgf_fields
 *
 * @pre An up-to-date PhvInfo object.
 */
class Cluster : public Inspector, TofinoWriteContext {
 public:
    enum CCGF_contiguity_limit {Parser_Extract = 28, Metadata = 16};
                                // parser: 4x8b,4x16b,4x32b extractors per parse state
                                // metadata: extensive aggregation causes ccgf related cluster bloat
                                //           consequent pressure on phv allocation
    class Uses;
    //
 private:
    PhvInfo &phv_i;

    /// Map of field to cluster it belongs.
    ordered_map<PhvInfo::Field *, ordered_set<PhvInfo::Field *>*> dst_map_i;
    /// Maintains unique cluster pointers.
    /// There is always a single owner to a cluster
    //  e.g., [b]-->(b,d,x) & op c d => [c]-->(c,b,d,x), lhs_unique set: +insert(c)-remove(b,d,x)
    ordered_set<PhvInfo::Field *> lhs_unique_i;
    /// Destination of current statement.
    PhvInfo::Field *dst_i = nullptr;
    /// All POV fields.
    /// POV bits (one per header) only used for deparsing
    std::list<PhvInfo::Field *> pov_fields_i;
    /// POV fields not in cluster, need to be PHV allocated.
    std::list<PhvInfo::Field *> pov_fields_not_in_cluster_i;
    /// Fields that are not used through mau pipeline.
    std::list<PhvInfo::Field *> fields_no_use_mau_i;
    Uses *uses_i;

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
    void create_dst_map_entry(PhvInfo::Field *);
    void set_field_range(const IR::Expression&);
    void insert_cluster(PhvInfo::Field *, PhvInfo::Field *);
    bool is_ccgf_owner_in_cluster(PhvInfo::Field *, PhvInfo::Field *);
    //
    void sanity_check_field_range(const std::string&);
    void sanity_check_clusters(const std::string&, PhvInfo::Field *);
    void sanity_check_clusters_unique(const std::string&);
    void sanity_check_fields_use(
        const std::string&,
        ordered_set<PhvInfo::Field *>,       // all fields
        ordered_set<PhvInfo::Field *>,       // cluster fields
        ordered_set<PhvInfo::Field *>,       // all - cluster
        ordered_set<PhvInfo::Field *>,       // pov fields
        ordered_set<PhvInfo::Field *>);      // no mau fields
    //
 public:
    //
    Cluster(PhvInfo &p);                     // NOLINT(runtime/explicit)
    //
    PhvInfo &phv()                                          { return phv_i; }
    //
    static void set_field_range(PhvInfo::Field *field, int container_width = 0);
    //
    ordered_map<PhvInfo::Field *, ordered_set<PhvInfo::Field *>*>& dst_map() {
        return dst_map_i;
    }
    //
    std::list<PhvInfo::Field *>& pov_fields()               { return pov_fields_i; }
    std::list<PhvInfo::Field *>& pov_fields_not_in_cluster()
                                                            { return pov_fields_not_in_cluster_i; }
    //
    void set_deparsed_flag();
    void deparser_ccgf_phv();
    void deparser_ccgf_t_phv();
    //
    std::list<PhvInfo::Field *>& fields_no_use_mau()        { return fields_no_use_mau_i; }
    void compute_fields_no_use_mau();
    void sort_fields_remove_non_determinism();
    //
    Uses* uses()  { return uses_i; }
};
//
//
class Cluster::Uses : public Inspector {
 public:
    bitvec      use_i[2][2];
    /*                |  ^- gress                 */
    /*                0 == use in parser/deparser */
    /*                1 == use in mau             */
    bitvec      deparser_i[2];
    /*                |    ^- gress               */
    /*                 == use in deparser         */
    //
    explicit Uses(PhvInfo &p) : phv(p) { }
    //
    bool is_referenced(PhvInfo::Field *f);
    bool is_deparsed(PhvInfo::Field *f);
    bool is_used_mau(PhvInfo::Field *f);
    bool is_used_parde(PhvInfo::Field *f);
    //
 private:
    PhvInfo       &phv;
    gress_t             thread;
    bool                in_mau;
    bool                in_dep;
    bool preorder(const IR::Tofino::Parser *p);
    bool preorder(const IR::Tofino::Deparser *d);
    bool preorder(const IR::MAU::TableSeq *);
    bool preorder(const IR::Expression *e);
};  // Uses
//
//
std::ostream &operator<<(std::ostream &, ordered_set<PhvInfo::Field *>*);
std::ostream &operator<<(std::ostream &, std::vector<PhvInfo::Field *>&);
std::ostream &operator<<(
    std::ostream&,
    ordered_map<PhvInfo::Field *, ordered_set<PhvInfo::Field *>*>&);
std::ostream &operator<<(std::ostream &, Cluster &);
//
#endif /* _TOFINO_PHV_CLUSTER_H_ */
