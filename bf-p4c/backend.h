/*
Copyright 2013-present Barefoot Networks, Inc. 

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#ifndef BF_P4C_BACKEND_H_
#define BF_P4C_BACKEND_H_

#include "ir/ir.h"
#include "bf-p4c-options.h"

#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/cluster.h"
#include "bf-p4c/phv/cluster_phv_req.h"
#include "bf-p4c/phv/cluster_phv_interference.h"
#include "bf-p4c/phv/cluster_phv_mau.h"

namespace BFN {

class PHV_AnalysisPass : public PassManager {
 private:
    SymBitMatrix mutually_exclusive_field_ids;
    Cluster cluster;                            // cluster analysis
    Cluster_PHV_Requirements cluster_phv_req;   // cluster PHV requirements
    PHV_Interference cluster_phv_interference;  // intra-cluster PHV Interference Graph
    PHV_MAU_Group_Assignments cluster_phv_mau;  // cluster PHV Container placements

 public:
    PHV_MAU_Group_Assignments& group_assignments() { return cluster_phv_mau; }

    PHV_AnalysisPass(const BFN_Options &options, PhvInfo &phv, PhvUse &uses,
                     FieldDefUse &defuse, DependencyGraph &deps);
};

class PHV_AllocPass : public PassManager {
 private:
    PhvInfo                   &phv;

 public:
    PHV_AllocPass(const BFN_Options &options, PhvInfo &phv, PhvUse &uses,
                  PHV_MAU_Group_Assignments &cluster_phv_mau);

    void end_apply() override {
         if (Log::verbose())
             std::cout << phv; }
};

class Backend : public PassManager {
    PhvInfo phv;
    PhvUse uses;
    DependencyGraph deps;
    FieldDefUse defuse;
    PHV_AnalysisPass phv_analysis;
    PHV_AllocPass phv_alloc;

 public:
    explicit Backend(const BFN_Options& options);
};

}  // namespace BFN

#endif /* BF_P4C_BACKEND_H_ */
