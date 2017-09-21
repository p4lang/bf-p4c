#ifndef BF_P4C_PHV_PHV_ANALYSIS_H_
#define BF_P4C_PHV_PHV_ANALYSIS_H_

#include "ir/ir.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/phv/cluster.h"
#include "bf-p4c/phv/cluster_phv_req.h"
#include "bf-p4c/phv/cluster_phv_interference.h"
#include "bf-p4c/phv/cluster_phv_mau.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "lib/symbitmatrix.h"

class PHV_AnalysisPass : public PassManager {
 private:
    SymBitMatrix mutually_exclusive_field_ids;
    Cluster cluster;                            // cluster analysis
    Cluster_PHV_Requirements cluster_phv_req;   // cluster PHV requirements
    PHV_Interference cluster_phv_interference;  // intra-cluster PHV Interference Graph
    PHV_MAU_Group_Assignments cluster_phv_mau;  // cluster PHV Container placements

 public:
    PHV_AnalysisPass(const BFN_Options &options, PhvInfo &phv, PhvUse &uses,
                     FieldDefUse &defuse, DependencyGraph &deps);
};

#endif /* BF_P4C_PHV_PHV_ANALYSIS_H_ */
