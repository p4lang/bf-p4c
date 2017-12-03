#ifndef EXTENSIONS_BF_P4C_PHV_ANALYSIS_FIELD_INTERFERENCE_H_
#define EXTENSIONS_BF_P4C_PHV_ANALYSIS_FIELD_INTERFERENCE_H_

#include "bf-p4c/phv/make_clusters.h"
#include "bf-p4c/phv/utils.h"
#include "ir/ir.h"
#include "lib/ordered_map.h"
#include "lib/symbitmatrix.h"

/** Generate a field-to-field interference graph for all fields referenced in the program and use
  * vertex coloring to create sets of mutually exclusive fields
  *
  * @pre Clusters determined by the MakeClusters pass, with all clusters separated into PHV and TPHV
  * clusters
  *
  * @post Maps corresponding to sets of mutually exclusive fields, with each set corresponding to a
  * single color determined by vertex coloring
  * Currently, we generate four separate maps: phv_overlays_ingress, phv_overlays_egress,
  * tphv_overlays_ingress, and tphv_overlays_egress
  */
class FieldInterference : public Visitor {
 public:
    using FieldColorMap = ordered_map<int, std::vector<PHV::Field *>>;
    using FieldVector = std::vector<PHV::Field *>;

 private:
    const Clustering&           clustering_i;
    SymBitMatrix&               mutex_i;

    /// Stores a mapping from a field to its corresponding cluster
    /// Without field slicing, the ordered_set will only contain 1 cluster
    ordered_map<PHV::Field*, ordered_set<PHV::AlignedCluster*>> field_to_cluster_map;

    /// Stores sets of mutually exclusive fields belonging to ingress
    FieldColorMap ingress_overlays;
    /// Stores sets of mutually exclusive fields belonging to egress
    FieldColorMap egress_overlays;

    /** @return all referenced fields in the program that belong to the list of clusters and the
      * gress specified by @clusters and @gress respectively
      */
    FieldVector getAllReferencedFields(std::vector<PHV::AlignedCluster*>& clusters, gress_t gress);

    /** Build a field interference graph for all the fields
      * @returns a FieldColorMap containing sets of mutually exclusive fields, from among the fields
      * in @fields
      */
    FieldColorMap constructFieldInterference(FieldVector& fields);

    /** Pretty print a FieldColorMap, containing the results of vertex coloring on the field
      * interference graph
      */
    void printFieldColorMap(FieldColorMap& m);

 public:
    FieldInterference(const Clustering& cluster, SymBitMatrix& mutex_m)
        : clustering_i(cluster), mutex_i(mutex_m) { }

    /** Entry point for the FieldInterference pass
      * Calls constructFieldInterference() to generate separate FieldColorMaps corresponding to PHV
      * ingress, PHV egress, TPHV ingress, and TPHV egress fields
      */
    const IR::Node* apply_visitor(const IR::Node *, const char *name = 0) override;
};  // class FieldInterference

#endif /* EXTENSIONS_BF_P4C_PHV_ANALYSIS_FIELD_INTERFERENCE_H_ */
