#ifndef BF_P4C_PHV_CLUSTER_H_
#define BF_P4C_PHV_CLUSTER_H_

#include "phv.h"
#include "phv_parde_mau_use.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/ordered_set.h"
#include "lib/range.h"
#include "bf-p4c/ir/thread_visitor.h"
#include "bf-p4c/ir/tofino_write_context.h"
#include "bf-p4c/parde/clot_info.h"

namespace PHV {
class Field;
}  // namespace PHV

class PhvInfo;

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
 * This pass also fills in the following PHV::Field fields:
 *  - phv_use_lo
 *  - phv_use_hi
 *  - ccgf
 *  - ccgf_fields
 *
 * @pre An up-to-date PhvInfo object.
 */
class Cluster : public PassManager {
 public:
    enum CCGF_contiguity_limit {Parser_Extract = 28, Metadata = 16};
                                // parser: 4x8b,4x16b,4x32b extractors per parse state
                                // metadata: extensive aggregation causes ccgf related cluster bloat
                                //           consequent pressure on phv allocation

    using Cluster_t = ordered_set<PHV::Field*>;

 private:
    PhvInfo& phv_i;
    PhvUse& uses_i;
    const ClotInfo& clot_i;

    /// Map of field to cluster it belongs.
    ordered_map<PHV::Field *, Cluster_t *> dst_map_i;
    /// Maintains unique cluster pointers.
    /// There is always a single owner to a cluster
    //  e.g., [b]-->(b,d,x) & op c d => [c]-->(c,b,d,x), lhs_unique set: +insert(c)-remove(b,d,x)
    ordered_set<PHV::Field *> lhs_unique_i;
    /// All POV fields.
    /// POV bits (one per header) only used for deparsing
    std::list<PHV::Field *> pov_fields_i;
    /// POV fields not in cluster, need to be PHV allocated.
    std::list<PHV::Field *> pov_fields_not_in_cluster_i;
    /// Fields that are not used through mau pipeline.
    std::list<PHV::Field *> fields_no_use_mau_i;

    class MakeCCGFs : public Inspector {
        Cluster& self;
        PhvInfo& phv_i;
        PhvUse&  uses_i;

        /** Analyze `validContainerRange` constraints on CCGF members to
         * compute a constraint for the CCGF as a whole, which is stored in
         * `PHV::Field::validCCGFRange_i` of its owner.
         *
         * Must be invoked after `ccgf_fields_i` has been populated.
         */
        void computeCCGFValidRange(PHV::Field* owner);

        bool preorder(const IR::HeaderRef*) override;
        void end_apply() override;
        void set_deparsed_flag();

     public:
        explicit MakeCCGFs(Cluster &self) : self(self), phv_i(self.phv_i), uses_i(self.uses_i) { }
    };

    class MakeClusters : public Inspector {
        Cluster& self;
        PhvInfo& phv_i;
        PhvUse&  uses_i;
        const ClotInfo& clot_i;

        bool preorder(const IR::Expression* e) override;
        void postorder(const IR::Primitive* primitive) override;
        void end_apply() override;

        void create_dst_map_entry(PHV::Field *);
        void insert_cluster(PHV::Field *, PHV::Field *);
        bool is_ccgf_owner_in_cluster(PHV::Field *, PHV::Field *);

        void compute_fields_no_use_mau();
        void deparser_ccgf_phv();
        void deparser_ccgf_t_phv();
        void sort_fields_remove_non_determinism();

        void sanity_check_field_range(const std::string&);
        void sanity_check_clusters(const std::string&, PHV::Field *);
        void sanity_check_clusters_unique(const std::string&);
        void sanity_check_fields_use(
            const std::string&,
            ordered_set<PHV::Field *>&,       // all fields
            ordered_set<PHV::Field *>&,       // cluster fields
            ordered_set<PHV::Field *>&,       // all - cluster
            ordered_set<PHV::Field *>&,       // pov fields
            ordered_set<PHV::Field *>&);      // no mau fields

     public:
        explicit MakeClusters(Cluster &self)
        : self(self), phv_i(self.phv_i), uses_i(self.uses_i), clot_i(self.clot_i) { }
    };
    //
 public:
    Cluster(PhvInfo &p, PhvUse &u, const ClotInfo& c) : phv_i(p), uses_i(u), clot_i(c) {
        addPasses({
            new MakeCCGFs(*this),
            new MakeClusters(*this) });
    }

    static void set_field_range(PhvInfo& phv, const IR::Expression&);
    static void set_field_range(PHV::Field *field, int container_width = 0);

    // Accesssor methods
    ordered_map<PHV::Field *, Cluster_t *>& dst_map() {
        return dst_map_i; }
    std::list<PHV::Field *>& pov_fields() {
        return pov_fields_i; }
    std::list<PHV::Field *>& pov_fields_not_in_cluster() {
        return pov_fields_not_in_cluster_i; }
    std::list<PHV::Field *>& fields_no_use_mau() {
        return fields_no_use_mau_i; }
};

std::ostream &operator<<(std::ostream &, ordered_set<PHV::Field *>*);
std::ostream &operator<<(std::ostream &, std::vector<PHV::Field *>&);
std::ostream &operator<<(
    std::ostream&,
    ordered_map<PHV::Field *, ordered_set<PHV::Field *>*>&);
std::ostream &operator<<(std::ostream &, Cluster &);

#endif /* BF_P4C_PHV_CLUSTER_H_ */
