#ifndef BF_P4C_MAU_CHARACTERIZE_POWER_H_
#define BF_P4C_MAU_CHARACTERIZE_POWER_H_

#include <boost/optional.hpp>
#include <cmath>
#include <fstream>
#include <iostream>
#include <map>
#include <queue>
#include <stack>
#include "version.h"
#include "bf-p4c/device.h"
#include "bf-p4c/mau/default_next.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "lib/error.h"


class SimpleTableNode {
 public:
  const UniqueId unique_id_;  // this is really a name
  const uint16_t id;  // node id (used for dot output)
  std::vector<SimpleTableNode*> parents_;
  std::vector<SimpleTableNode*> children_;
  std::map<SimpleTableNode*, cstring> edge_names_ = {};
  explicit SimpleTableNode(UniqueId uniq_id, uint16_t id) : unique_id_(uniq_id), id(id) {}
  void add_parent(SimpleTableNode *parent);
  void add_child(SimpleTableNode *child, cstring edge_name);

  cstring getName() {
    return unique_id_.build_name();
  }
};

class SimpleTableGraph {
    std::map<UniqueId, SimpleTableNode*> nodes_ = {};
    SimpleTableNode* root_;
    uint16_t running_id_;
    uint16_t getNextID() { return running_id_++; }

 private:
  void topo_visit(SimpleTableNode *node,
                  std::stack<SimpleTableNode*> *stack,
                  std::map<SimpleTableNode*, bool> *visited);

 public:
  explicit SimpleTableGraph(cstring gress) : running_id_(1), name_(gress) {
    UniqueId root_uid;
    root_uid.name = "$root";
    root_ = new SimpleTableNode(root_uid, 0);
    nodes_.emplace(root_uid, root_);
  }
  cstring name_;  // graph name, e.g. ingress or egress
  void add_edge(UniqueId parent_uid, UniqueId child_uid, cstring edge_name);
  void to_dot(cstring filename);
  SimpleTableNode* getRoot() { return root_; }
  std::vector<SimpleTableNode*> topo_sort();
};

class CharacterizePower: public MauInspector {
  enum dep_t {DEP_CONCURRENT = 0, DEP_ACTION = 1, DEP_MATCH = 2};

 /*
  * rams_read
  *    The total number of RAMs read.
  * rams_write
  *    The total number of RAMs written.  Only attached synth-2-port
  *    resources can write RAMs.
  * tcam_read
  *    The total number of TCAMs read.  Ternary tables have to read
  *    all TCAMs.
  * map_rams_read
  *    The total number of MapRAMs read.  MapRAMs are read by synth-2-port,
  *    idletime, and meter color.
  * map_rams_write
  *    The total number of MapRAMs written.  MapRAMs are written by
  *    synth-2-port, idletime, and meter color.
  * deferred_rams_read
  *    The total number of deferred RAMs read.  Deferred RAMs are read
  *    by meters and counters that run at EOP time.
  * deferred_rams_write
  *    The total number of DeferredRAMs written.  Deferred RAMs are written
  *    by meters and counters that run at EOP time.
  */
  struct PowerMemoryAccess {
    uint16_t ram_read = 0;
    uint16_t ram_write = 0;
    uint16_t tcam_read = 0;
    uint16_t map_ram_read = 0;
    uint16_t map_ram_write = 0;
    uint16_t deferred_ram_read = 0;
    uint16_t deferred_ram_write = 0;

    PowerMemoryAccess() :
      ram_read(0), ram_write(0),
      tcam_read(0),
      map_ram_read(0), map_ram_write(0),
      deferred_ram_read(0), deferred_ram_write(0) {}

    explicit PowerMemoryAccess(uint16_t ram_read, uint16_t ram_write,
                               uint16_t tcam_read,
                               uint16_t map_ram_read, uint16_t map_ram_write,
                               uint16_t deferred_ram_read, uint16_t deferred_ram_write) :
      ram_read(ram_read), ram_write(ram_write),
      tcam_read(tcam_read),
      map_ram_read(map_ram_read), map_ram_write(map_ram_write),
      deferred_ram_read(deferred_ram_read), deferred_ram_write(deferred_ram_write) {}


    friend std::ostream &operator<<(std::ostream &out, const PowerMemoryAccess &p) {
      out << "Memory access:" << std::endl;
      out << "   RAMs read " << p.ram_read << std::endl;
      out << "   RAMs write " << p.ram_write << std::endl;
      out << "   TCAMs read " << p.tcam_read << std::endl;
      out << "   MapRAMs read " << p.map_ram_read << std::endl;
      out << "   MapRAMs write " << p.map_ram_write << std::endl;
      out << "   Deferred RAMs read " << p.deferred_ram_read << std::endl;
      out << "   Deferred RAMs write " << p.deferred_ram_write << std::endl;
      return out;
     }

     PowerMemoryAccess &operator+=(const PowerMemoryAccess &p) {
       ram_read += p.ram_read;
       ram_write += p.ram_write;
       tcam_read += p.tcam_read;
       map_ram_read += p.map_ram_read;
       map_ram_write += p.map_ram_write;
       deferred_ram_read += p.deferred_ram_read;
       deferred_ram_write += p.deferred_ram_write;
       return *this;
     }

     PowerMemoryAccess operator+(const PowerMemoryAccess &p) const {
       PowerMemoryAccess rv = *this; rv += p; return rv; }
  };

  /**
    * Encapsulate information needed for summarizing table power in
    * a log file.
    * stage
    *     The stage the match table is in.
    * always_run
    *     A Boolean indicating this table is not on the 'critical' table
    *     control flow graph, but it is powered on due to the MAU stage
    *     dependency to the previous stage.
    * weight
    *     A double indicating the table power weight (normalized).
    * table_name
    *     A string indicating the table name.
    */
  struct PowerTableSummary {
    uint16_t stage;
    bool always_run;
    double weight;
    cstring table_name;

    PowerTableSummary() :
      stage(-1), always_run(false), weight(0.0), table_name("") {}

    explicit PowerTableSummary(uint16_t stage,
                               bool always_run,
                               double weight,
                               cstring table_name) :
      stage(stage), always_run(always_run),
      weight(weight), table_name(table_name) {}
  };


  /* --------------------------------------------------------
   *  Device memory power numbers.
   * --------------------------------------------------------*/
  // FIXME(mea): Ideally, this would reside in a common device model.
  double max_power_ = 0.0;  // Value for all 4 pipes.
  double excess_threshold_ = 0.0;  // additional power given with disable_power_check
  double pipes_in_use_ = 4.0;  // FIXME(mea): Revisit for different architecture variants

  double ram_read_power_ = 0.0;  // Values for single access in one pipe.
  double ram_write_power_ = 0.0;
  double tcam_read_power_ = 0.0;
  double map_ram_read_power_ = 0.0;
  double map_ram_write_power_ = 0.0;
  double deferred_ram_read_power_ = 0.0;
  double deferred_ram_write_power_ = 0.0;

  // For computing the normalized weight, this variable holds the
  // minimum memory-type power access.
  double min_power_access_ = 0.0;

  // For computing MAU stage latencies (number of clock cycles).
  // Refer to Tofino MAU microarchitecture document (Section 2.4)
  // for more information.
  uint16_t base_delay_ = 0;
  uint16_t base_predication_delay_ = 0;
  uint16_t tcam_delay_ = 0;
  uint16_t selector_delay_ = 0;
  uint16_t meter_lpf_delay_ = 0;
  uint16_t stateful_delay_ = 0;
  uint16_t mau_corner_turn_latency_ = 0;
  uint16_t concurrent_latency_contribution_ = 0;
  uint16_t action_latency_contribution_ = 0;

  // For scaling MAU power based on potential deparser to pmarb back-pressure.
  uint16_t deparser_max_phv_valid_ = 0;
  uint16_t cycles_to_issue_credit_to_pmarb_ = 0;
  uint16_t deparser_throughput_scaling_starts_ = 0;
  uint16_t pmarb_cycles_from_receive_credit_to_issue_phv_to_mau_ = 0;

  // On Tofino, there is a minimum egress MAU pipeline latency.
  uint16_t minimum_egress_pipe_latency_ = 0;

  /* --------------------------------------------------------
   *  Worst-case power calculation helper variables.
   * --------------------------------------------------------*/
  DependencyGraph& dep_graph_;
  DefaultNext default_next_;
#if BAREFOOT_INTERNAL
    bool no_power_check_ = false;
#endif
  bool display_power_budget_;
  bool disable_power_check_ = false;
  std::string logFileName_;

  // First tables in the relevant control flow.
  const IR::MAU::Table* ingress_root_;
  const IR::MAU::Table* egress_root_;
  std::map<gress_t, SimpleTableGraph*> gress_to_graph_ = {};
  std::stack<UniqueId> ingress_worst_case_path_;
  std::stack<UniqueId> egress_worst_case_path_;
  double ingress_worst_power_ = 0.0;
  double egress_worst_power_ = 0.0;

  // map from UniqueId to Boolean indicating
  // if it will run at EOP.
  // The UniqueId is the attached table's UniqueId.
  std::map<UniqueId, bool> counter_runs_at_eop = {};
  std::map<UniqueId, bool> meter_runs_at_eop = {};
  // for keeping track if have LPF or WRED 'meter'
  std::map<UniqueId, bool> meter_is_lpf_or_wred = {};
  // stores maximum number of selector members
  // (more than 120 requires multiple RAM words)
  std::map<UniqueId, int> selector_group_size_ = {};

  // map from match table UniqueId to tuple of memory accesses
  // A match table will also include any attached table's memory accesses used.
  std::map<UniqueId, PowerMemoryAccess> table_memory_access = {};
  std::map<UniqueId, PowerTableSummary> table_unique_id_to_power_summary_ = {};

  // map from attached table's UniqueId to memory access struct.
  // Only populated with stats, meters, stateful, selector, action data.
  // This is needed because a shared attached table is only attached to one
  // of its match tables, but each match table that accesses shared table
  // needs to factor in power used by its attached.
  std::map<UniqueId, PowerMemoryAccess> attached_memory_usage = {};
  // map from match table UniqueId to its attached gateway UniqueId, if any.
  std::map<UniqueId, UniqueId> table_to_attached_gateway = {};

  // Need to update these to include accesses from 'attached_memory_usage'
  // once that information is found.
  IR::Vector<IR::MAU::Table> match_tables_with_unattached;

  // For calculating latencies
  // map from stage number to Boolean indicating if resource type in use.
  // stage numbers will be encoded as:
  //      0 to n-1 for ingress stages
  //      n to 2n-1 for egress stages
  std::map<uint16_t, bool> has_exact_ = {};
  // has_tcam_ would also include ternary result busses in ram array
  std::map<uint16_t, bool> has_tcam_ = {};
  std::map<uint16_t, bool> has_meter_lpf_or_wred_ = {};
  std::map<uint16_t, bool> has_selector_ = {};
  std::map<uint16_t, uint16_t> max_selector_words_ = {};  // maps to maximum selector words
  std::map<uint16_t, bool> has_stateful_ = {};
  std::map<uint16_t, bool> has_stats_ = {};

  std::map<uint16_t, dep_t> stage_dependency_to_previous_ = {};

  std::map<uint16_t, std::vector<const IR::MAU::Table*>> stage_to_tables_ = {};

  uint16_t longest_table_name_ = 10;  // used for mau.power.log table formatting

  /* --------------------------------------------------------
   *  Function definitions.
   * --------------------------------------------------------*/
  Visitor::profile_t init_apply(const IR::Node *root) override;
  void end_apply() override;
  bool preorder(const IR::BFN::Pipe *p) override;
  void postorder(const IR::BFN::Pipe *p) override;

  bool preorder(const IR::MAU::Table* t) override;
  void postorder(const IR::MAU::Table* t) override;
  bool preorder(const IR::MAU::Meter *m) override;
  bool preorder(const IR::MAU::Counter *c) override;
  bool preorder(const IR::MAU::Selector *sel) override;

  bool preorder(const IR::MAU::TableSeq* seq) override;
  void postorder(const IR::MAU::TableSeq* seq) override;

  // copied from asm_output.cpp, but changed to return UniqueId
  UniqueId next_for(const IR::MAU::Table *tbl, cstring what, const DefaultNext &def);

 private:
  /**
    * Computes the worst-case power consumed given parameters that indicate
    * the number of different memory types read and written.
    * This function is intended to be called per logical table in each stage,
    * where the parameters include the sum of memories accessed by the
    * match table and all its attached tables.
    * For example, if an exact match table has a directly attached counter,
    * the parameters should have non-zero values for rams_read, rams_write,
    * map_rams_read, and map_rams_write.  If the counter runs at EOP time,
    * the deferred_rams_read and deferred_rams_write should have non-zero
    * values as well.
    * Note that the value this function returns should not be exposed
    * to an end-user.
    *
    * @param memory_access
    *    A structure containing how many memories of each type are read and
    *    written.
    * @return
    *    The total power consumed (in Watts) for all pipelines.
    */
  double compute_table_power(PowerMemoryAccess memory_access);

  /**
    * Returns a normalized weight of a table's power contribution.
    * We do not generally want to expose the raw Watts used by a table, as
    * this is considered Barefoot secret.
    * @return
    *     The normalized weight of the power contribution of this table.
    *     Note that this is normalized to one pipeline.
    */
  double compute_table_weight(double table_power);

  /**
    * Since table visit order does not guarantee that the match table
    * an unattached table is attached to in the IR, need a function
    * for after the traversal that fills in the memory accesses used
    * by these side effect tables.
    */
  void add_unattached_memory_accesses();

  /**
    * Computes a specific pipeline latency (in clock cycles).
    *
    */
  uint16_t compute_pipe_latency(uint16_t pipe);

  /**
    * Computes the stage latency of a specific MAU stage (in clock cycles).
    * Note that stage is encoded such that stages 0 to n-1 are ingress and
    * n to 2n-1 are for egress.
    *
    */
  uint16_t compute_stage_latency(uint16_t stage);

  /**
    * Computes the dependency type from the provided MAU stage to the previous.
    * Note that stage is encoded such that stages 0 to n-1 are ingress and
    * n to 2n-1 are for egress.
    * Note that this function will enforce the minimum egress pipeline
    * latency by adding match dependencies between stages.
    * FIXME(mea): This function needs to properly propagate MAU features
    * between chains of action/concurrent stages so that their overall
    * stage latencies are balanced.
    */
  void compute_stage_dependencies(uint16_t pipe);

 public:
  explicit CharacterizePower(DependencyGraph& dep_graph,
#if BAREFOOT_INTERNAL
                              bool no_power_check,
#endif
                              bool display_power_budget,
                              bool disable_power_check) :
     dep_graph_(dep_graph),
#if BAREFOOT_INTERNAL
     no_power_check_(no_power_check),
#endif
     display_power_budget_(display_power_budget),
     disable_power_check_(disable_power_check) {
    if (Device::currentDevice() == Device::TOFINO) {
       double ram_scaling_factor = 1.88574;
       double tcam_scaling_factor = 0.62736;

       // Tofino Memory access power numbers (in Watts)
       max_power_ = 40.0;  // Value for all 4 pipes.
       excess_threshold_ = 10.0;
       ram_read_power_ = 0.012771 * ram_scaling_factor;
       ram_write_power_ = 0.023419 * ram_scaling_factor;
       tcam_read_power_ = 0.0398 * tcam_scaling_factor;
       map_ram_read_power_ = 0.0025861 * ram_scaling_factor;
       map_ram_write_power_ = 0.0030107 * ram_scaling_factor;
       deferred_ram_read_power_ = 0.0029238 * ram_scaling_factor;
       deferred_ram_write_power_ = 0.0020185 * ram_scaling_factor;

       base_delay_ = 20;
       base_predication_delay_ = 11;
       tcam_delay_ = 2;
       selector_delay_ = 8;
       meter_lpf_delay_ = 4;
       stateful_delay_ = 4;
       mau_corner_turn_latency_ = 4;
       concurrent_latency_contribution_ = 1;
       action_latency_contribution_ = 2;
       deparser_max_phv_valid_ = 288;
       cycles_to_issue_credit_to_pmarb_ = 28;
       pmarb_cycles_from_receive_credit_to_issue_phv_to_mau_ = 11;
       minimum_egress_pipe_latency_ = 160;

     } else if (Device::currentDevice() == Device::JBAY) {
       double ram_scaling_factor = 1.0;  // No number available.
       double tcam_scaling_factor = 1.0;  // No number available.

       // Note note note: When table placement starts leveraging Tofino2's
       // different predication mechanism, we will have to rewrite how
       // the worst case table control flow path is found.  For now,
       // we will default to Tofino's mechanism.
       // Enforcing a pessimistic limit is better than setting customer
       // expectations that anything is permissible.

       // Tofino2 Memory access power numbers (in Watts)
       // These numbers are currently based on library models, not measurements.
       // This will be re-visited once real devices are in our lab.
       // When a number was not available, we defaulted to Tofino's unscaled value.
       max_power_ = 52.0;  // FIXME: Scaled Tofino by 1.3, but do not know value yet.
       excess_threshold_ = 10.0;
       ram_read_power_ = 0.00784163 * ram_scaling_factor;
       ram_write_power_ = 0.023419 * ram_scaling_factor;  // No number available.
       tcam_read_power_ = 0.03 * tcam_scaling_factor;
       map_ram_read_power_ = 0.0025861 * ram_scaling_factor;  // No number available.
       map_ram_write_power_ = 0.0030107 * ram_scaling_factor;  // No number available.
       deferred_ram_read_power_ = 0.0029238 * ram_scaling_factor;  // No number available.
       deferred_ram_write_power_ = 0.0020185 * ram_scaling_factor;  // No number available.

       base_delay_ = 20;
       base_predication_delay_ = 11;
       tcam_delay_ = 2;
       selector_delay_ = 8;
       meter_lpf_delay_ = 4;
       stateful_delay_ = 4;
       mau_corner_turn_latency_ = 0;  // No corner turn in Tofino2.
       concurrent_latency_contribution_ = 0;  // No concurrent in Tofino2.
       action_latency_contribution_ = 2;

       // FIXME: Do not know these 4 values yet, or whether deparser scaling will apply.
       // Once these numbers are known, update usages in CharacterizePower::postorder.
       deparser_max_phv_valid_ = 288;
       cycles_to_issue_credit_to_pmarb_ = 28;
       pmarb_cycles_from_receive_credit_to_issue_phv_to_mau_ = 11;
       minimum_egress_pipe_latency_ = 0;
     }

     deparser_throughput_scaling_starts_ =
       deparser_max_phv_valid_ - cycles_to_issue_credit_to_pmarb_ -
       pmarb_cycles_from_receive_credit_to_issue_phv_to_mau_;

     min_power_access_ = std::min(ram_read_power_, ram_write_power_);
     min_power_access_ = std::min(min_power_access_, tcam_read_power_);
     min_power_access_ = std::min(min_power_access_, map_ram_read_power_);
     min_power_access_ = std::min(min_power_access_, map_ram_write_power_);
     min_power_access_ = std::min(min_power_access_, deferred_ram_read_power_);
     min_power_access_ = std::min(min_power_access_, deferred_ram_write_power_);

     // Setup per-stage maps
     for (uint16_t stage = 0; stage < (2 * Device::numStages()); ++stage) {
       has_exact_.emplace(stage, false);
       has_tcam_.emplace(stage, false);
       has_meter_lpf_or_wred_.emplace(stage, false);
       has_selector_.emplace(stage, false);
       max_selector_words_.emplace(stage, 0);
       has_stateful_.emplace(stage, false);
       has_stats_.emplace(stage, false);
       if (Device::currentDevice() == Device::JBAY) {
         stage_dependency_to_previous_.emplace(stage, DEP_ACTION);
       } else {
         stage_dependency_to_previous_.emplace(stage, DEP_CONCURRENT);
       }
     }
  }

  SimpleTableGraph* get_graph(gress_t gress);
  std::string float2str(double d);
  uint16_t inline getStage(uint16_t logical_id, gress_t g) const {
    if (g == EGRESS) {
       return (logical_id / 16) + Device::numStages();
    } else {
       return logical_id / 16;
    }
  }
  cstring dep_to_name(dep_t dep) {
    if (dep == DEP_MATCH) {
      return "match";
    } else if (dep == DEP_ACTION) {
      return "action";
    } else {
      return "concurrent";
    }
  }
  cstring printFeatures();
  cstring printLatency();
  cstring printWorstPower();
  cstring printNormalizedWeights();
};

#endif /* BF_P4C_MAU_CHARACTERIZE_POWER_H_ */
