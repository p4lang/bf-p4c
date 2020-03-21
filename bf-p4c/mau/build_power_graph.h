#ifndef BF_P4C_MAU_BUILD_POWER_GRAPH_H_
#define BF_P4C_MAU_BUILD_POWER_GRAPH_H_

#include "mau_visitor.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/ir/control_flow_visitor.h"
#include "bf-p4c/mau/default_next.h"
#include "bf-p4c/mau/jbay_next_table.h"
#include "bf-p4c/mau/simple_power_graph.h"
#include "lib/ordered_set.h"

namespace MauPower {

/**
  * This class constructs the final placed MAU table control flow graph for
  * each thread of execution: ingress, egress, and ghost.
  */
class BuildPowerGraph : public MauInspector, BFN::ControlFlowVisitor {
 public:
  profile_t init_apply(const IR::Node *root) override;
  bool preorder(const IR::MAU::TableSeq *seq) override;
  bool preorder(const IR::MAU::Table *tbl) override;
  /**
    * Depending on compilation options, this function produces a dot graph
    * for each thread of execution.  
    */
  void end_apply(const IR::Node *root) override;

  BuildPowerGraph *clone() const override;
  void flow_merge(Visitor &v) override;

  SimplePowerGraph* get_graph(gress_t g);
  BuildPowerGraph(const NextTable* next_table_properties,
                  const BFN_Options& options);
  BuildPowerGraph(const BuildPowerGraph& other) = default;

 private:
  SimplePowerGraph* ingress_graph_;
  SimplePowerGraph* egress_graph_;
  SimplePowerGraph* ghost_graph_;
  DefaultNext* default_next_;
  const NextTable* next_table_properties_;
  const BFN_Options& options_;
  // Keep track of which logical tables are marked as always run.
  std::vector<UniqueId> always_run_;
  ordered_set<UniqueId> next_for(const IR::MAU::Table *tbl, cstring what) const;
};

};  // end namespace MauPower

#endif /* BF_P4C_MAU_BUILD_POWER_GRAPH_H_ */