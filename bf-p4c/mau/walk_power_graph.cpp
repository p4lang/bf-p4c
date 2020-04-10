#include <ctime>
#include <map>
#include <queue>
#include <set>
#include <vector>

#include "bf-p4c/common/run_id.h"
#include "bf-p4c/device.h"
#include "bf-p4c/logging/manifest.h"
#include "bf-p4c/mau/build_power_graph.h"
#include "bf-p4c/mau/determine_power_usage.h"
#include "bf-p4c/mau/jbay_next_table.h"
#include "bf-p4c/mau/mau_power.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/memories.h"
#include "bf-p4c/mau/simple_power_graph.h"
#include "bf-p4c/mau/walk_power_graph.h"
#include "ir/gress.h"
#include "ir/unique_id.h"
#include "lib/json.h"
#include "lib/path.h"
#include "lib/set.h"
#include "power_schema.h"
#include "version.h"

namespace MauPower {

bool WalkPowerGraph::preorder(const IR::MAU::Table* t) {
  external_names_.emplace(t->unique_id(), t->externalName());
  gress_map_.emplace(t->unique_id(), t->gress);
  stages_.emplace(t->unique_id(), t->stage());
  if (longest_table_name_ < t->externalName().size())
    longest_table_name_ = t->externalName().size();
  return true;
}

/**
  * 0. Clear MPR settings (since these steps will be done in a loop)
  * 1. Compute MPR settings (Tofino2+ only)
  * 2. Estimate power
  * 3. Update dependencies if can (if power exceeded) and go back to step 0
  * 4. Log results, send info to assembly generation.
  */
void WalkPowerGraph::end_apply(const IR::Node *root) {
  bool updated_deps = true;
  auto& spec = Device::mauPowerSpec();
  double rounding = spec.get_max_power() / 104729.0;
  double total_power = 0.0;

  mau_features_->update_deps_for_device();

  // If power check is not successful, attempt to add match dependencies
  // to bring the power down.  Match dependencies on Tofino can invoke
  // deparser throughput scaling as well as turning off some lookups.
  // On Tofino2+, match dependencies allow the next table / local / global exec
  // chains to resolve, which may allow fewer tables to be turned on per stage.
  while (updated_deps) {
    updated_deps = false;
    if (Device::currentDevice() != Device::TOFINO) {
      clear_mpr_settings();
      compute_mpr();
      if (check_mpr_conflict()) {
        updated_deps = true;
        continue; } }

    total_power = estimate_power();
    if (total_power > (spec.get_max_power() + rounding)) {
      updated_deps = mau_features_->try_convert_to_match_dep();
    } else {
      // power not exceeded, hooray!
      LOG4("Power check successful.");
    }
  }

  create_mau_power_log(root);
  create_mau_power_json(root);

  // log results (power.json, mau.power.log)
  // latency, features, power
  if (total_power > (spec.get_max_power() + rounding)) {
    double excess = total_power - spec.get_max_power();
    std::string s = float2str(excess);
    std::string error_msg = "Power worst case estimated budget exceeded by " + s + "W.\n";
    error_msg += "Too many memories are accessed in the worst case table control flow.\n";
    error_msg += "Adding control flow conditions to separate large table execution ";
    error_msg += "and/or splitting large tables may help.\n";
#if BAREFOOT_INTERNAL
    bool suppress = exceeds_stages_ || options_.no_power_check ||
                    (options_.disable_power_check &&
                     excess < (spec.get_excess_power_threshold() + rounding));
#else
    bool suppress = exceeds_stages_ ||
                    (options_.disable_power_check &&
                     excess < (spec.get_excess_power_threshold() + rounding));
#endif
    if (suppress) {
      std::string warn_msg = "Power check explicitly disabled.\n";
      warn_msg += "The generated binary can potentially cause the device to ";
      warn_msg += "exceed the published max power.\n";
      warn_msg += "Please make sure this profile is fully tested to confirm ";
      warn_msg += "system functionality under worst case conditions.\n";
      ::warning("%s", warn_msg);
      ::warning("%s", error_msg);
    } else {
      ::error("%s", error_msg);
    }
  }
}

void WalkPowerGraph::clear_mpr_settings() {
  for (auto ms : mpr_settings_) {
    delete ms.second; }
  mpr_settings_.clear();
  for (gress_t g : Device::allGresses()) {
    mpr_settings_.emplace(g, new MprSettings(g, *mau_features_)); }
}

/** Match Power config
 * Match power config (whether or not to power the match of tables in a stage) depends
 * on the predication of a previous stage.  Problem is, if the stage is not match dependent
 * on the previous stage, the previous stage's predication output will be too late for
 * the match, so we need to use an earlier stage's predication output (not the immediately
 * previous stage).
 *
 * To manage all this, we divide the stages in each thread into "non-match-dependent groups"
 * The first stage in each group is match dependent on the previous stage and subsequent stages
 * in the group are not match dependent on the previous stage.  Then we forward the predication
 * output of the last stage in each group to all the stages in the following group for match
 * power enable/disable.  Each global exec bit and each long branch tag can be separately
 * forwarded (or not), so as long as different threads agree on who is using each bit, they
 * can use different match/action dependency for each stage.  So we might have:
 *
 * 
 *  stage    0   1   2   3   4   5   6   7   8  ...
 *         +---+---+---+---+---+---+---+---+---+
 * ingress | M | M | A | A | A | M | M | A | A |
 *         +---+---+---+---+---+---+---+---+---+
 *  egress | M | A | A | M | A | M | A | M | M |
 *         +---+---+---+---+---+---+---+---+---+
 *
 * so in ingress the groups are stage 0, stages 1-4, stage 5, and stages 6-8, while in egress
 * they are stages 0-2, stages 3-4, stages 5-6, stage 7, and stage 8.
 * All the tables in ingress stages 1-4 have their match power determined from the predication
 * output of stage 0, and we forward that output across all 4 stages.  Egress stages 3-4 have
 * their match power determined by the predication output of stage 2.  This means that ingress
 * and egress need to agree on who gets to use each mpr bus global exec bit coming out of stage
 * 0 and stage 2, or there will be a problem.  So after we calculate the mpr bus usage, we
 * check if there are any conflicts between ingress and egress (check_mpr_conflict()) and if
 * there are, we change a stage to be match dependent (spliting the stage group) and redo
 * mpr config.
 */
void WalkPowerGraph::compute_mpr() {
  if (next_table_properties_)
    LOG4("" << *next_table_properties_);

  for (gress_t g : Device::allGresses()) {
    MprSettings* mpr = mpr_settings_.at(g);
    SimplePowerGraph* graph = graphs_->get_graph(g);
    // Initialize MPR settings.
    int last_match_dep_stage = -1;  // last stage in the previous group of stages
    for (int stage = 0; stage < Device::numStages(); ++stage) {
      if (disable_mpr_config_)
        break;  // set all tables to MPR always run instead
      if (mau_features_->get_dependency_for_gress_stage(g, stage) == DEP_MATCH)
        last_match_dep_stage = stage-1;
      mpr->set_mpr_stage(stage, last_match_dep_stage+1);

      int always_run = 0;
      if (last_match_dep_stage < 0) {
        for (auto tbl : mau_features_->stage_to_tables_[g][stage]) {
          if (tbl->logical_id) always_run |= (1 << *tbl->logical_id); }
      } else {
        for (auto tbl : mau_features_->stage_to_tables_[g][stage]) {
          if (!tbl->logical_id) continue;  // ignore unplaced and non- tables
          if (tbl->always_run == IR::MAU::AlwaysRun::TABLE) {
            always_run |= (1 << *tbl->logical_id);
            continue; }
          // ordered_set can be safely appended to while iterating over it
          ordered_set<const IR::MAU::Table *> tables = { tbl };
          // First we need to find all the tables that might directly or indirectly invoke
          // this table that are in the same non-match-dep group of stages.  We then need
          // enable match power for this table if any of them might run.
          for (auto t : tables) {
            for (auto p_uid : graph->predecessors(t->unique_id())) {
              if (!mau_features_->uid_to_table_.count(p_uid)) continue;
              auto p = mau_features_->uid_to_table_.at(p_uid);
              if (!tables.count(p) && p->stage() > last_match_dep_stage)
                tables.insert(p); } }
          // Now look through the predecessors of all of those tables and enable match power
          // on this table based on them
          int glob_exec = 0;    // incoming global exec bits dependent on
          int long_branch = 0;  // incoming long branch tags dependent on
          int next_tables = 0;  // incoming next table values dependent on
          for (auto t : tables) {
            auto &predecessors = graph->predecessors(t->unique_id());
            if (t->always_run == IR::MAU::AlwaysRun::TABLE || predecessors.empty()) {
              always_run |= (1 << *tbl->logical_id);
              // this table needs to be mpr always run, so don't need to trigger
              // it any other way
              glob_exec = 0;
              long_branch = 0;
              next_tables = 0;
              break;
            } else {
              BUG_CHECK(t->stage() > last_match_dep_stage, "inconsistent stage");
              for (auto p_uid : predecessors) {
                if (!mau_features_->uid_to_table_.count(p_uid)) continue;
                auto p = mau_features_->uid_to_table_.at(p_uid);
                if (p->stage() > last_match_dep_stage) continue;
                if (p->resources->table_format.next_table_bits() > 3) {
                  // Annoying corner case -- tables that have too many potential next tables
                  // for the next table map cannot use global_exec/long_branch and must use
                  // the next table.  Should mark these special corner case tables in the IR.
                  next_tables |= 1 << *t->logical_id;
                } else if (t->stage() == p->stage() + 1) {
                  // trigger via global exec
                  glob_exec |= (1 << *t->logical_id);
                } else {
                  // trigger via long branch or next table
                  int tag = next_table_properties_->long_branch_tag_for(p_uid, t->unique_id());
                  if (tag >= 0) {
                    long_branch |= 1 << tag;
                  } else {
                    next_tables |= 1 << *t->logical_id;
                  }
                }
              }
            }
          }
          int s = last_match_dep_stage;
          mpr->glob_exec_use[s] |= glob_exec;
          mpr->long_branch_use[s] |= long_branch;
          while (++s < stage) {
            mpr->glob_exec_use[s] |= glob_exec;
            mpr->long_branch_use[s] |= long_branch;
            mpr->set_or_mpr_bus_dep_glob_exec(s, glob_exec);
            mpr->set_or_mpr_bus_dep_long_brch(s, long_branch);
          }
          for (auto exec_bit : bitvec(glob_exec))
            mpr->set_or_mpr_global_exec(stage, exec_bit, 1 << *tbl->logical_id);
          for (auto lb_tag : bitvec(long_branch))
            mpr->set_or_mpr_long_branch(stage, lb_tag, 1 << *tbl->logical_id);
          for (auto nxt : bitvec(next_tables))
            mpr->set_or_mpr_next_table(stage, nxt, 1 << *tbl->logical_id);
        }
      }
      mpr->set_mpr_always_run(stage, always_run);
    }  // stage

    // Bypass normal MPR config.
    if (disable_mpr_config_) {
      for (int stage = 0; stage < Device::numStages(); ++stage) {
        mpr->set_mpr_stage(stage, stage);  // mpr stage doesn't matter when everything is always run
        int always_run = 0;
        for (auto tbl : mau_features_->stage_to_tables_[g][stage]) {
          switch (tbl->always_run) {
          case IR::MAU::AlwaysRun::NONE:
            break;

          case IR::MAU::AlwaysRun::ACTION:
            continue;

          case IR::MAU::AlwaysRun::TABLE:
            LOG4("Table " << tbl->externalName() << " was marked as always run.");
            break;
          }

          always_run |= (1 << *tbl->logical_id);
        }
        mpr->set_or_mpr_always_run(stage, always_run);
    } }
  }  // gress
}

bool WalkPowerGraph::check_mpr_conflict() {
  bool change = false;
  for (int stage = 0; stage < Device::numStages(); ++stage) {
    auto ig_dep = mau_features_->get_dependency_for_gress_stage(INGRESS, stage);
    auto eg_dep = mau_features_->get_dependency_for_gress_stage(EGRESS, stage);
    if (ig_dep != eg_dep) {
      auto ig_mpr = mpr_settings_.at(INGRESS);
      auto eg_mpr = mpr_settings_.at(EGRESS);
      if ((ig_mpr->glob_exec_use[stage] & eg_mpr->glob_exec_use[stage]) != 0 ||
          (ig_mpr->long_branch_use[stage] & eg_mpr->long_branch_use[stage]) != 0) {
        change = true;
        if (ig_dep == DEP_MATCH) {
          mau_features_->stage_dep_to_previous_[EGRESS][stage] = DEP_MATCH;
        } else if (eg_dep == DEP_MATCH) {
          mau_features_->stage_dep_to_previous_[INGRESS][stage] = DEP_MATCH;
          mau_features_->stage_dep_to_previous_[GHOST][stage] = DEP_MATCH;
        } else {
          BUG("impossible gress dep combo ig=%d eg=%d", ig_dep, eg_dep);
        }
      }
    }
  }
  return change;
}

/**
  * Power estimation is different for Tofino vs. Tofino2 and beyond, due
  * to how MPR works.
  * This is called in a loop, so each call should clear things it fills in.
  */
double WalkPowerGraph::estimate_power() {
  gress_powers_.clear();
  on_critical_path_.clear();
  always_powered_on_.clear();
  if (Device::currentDevice() == Device::TOFINO)
    return estimate_power_tofino();
  else
    return estimate_power_non_tofino();
}

/**
  * To find the worst-case path, first find the topological sort of
  * the control flow graph, and then compute maximum distances to
  * each node.  A topological sort ensures all parent nodes have been
  * visited, so the worst case path to a given node will go through
  * the worst-case path to any of its parents.
  */
double WalkPowerGraph::estimate_power_tofino() {
  double NINF = -(std::pow(2.0, 32) - 1);  // small enough for practical purposes
  for (gress_t g : Device::allGresses()) {
    SimplePowerGraph *graph = graphs_->get_graph(g);
    std::vector<Node*> topo = graph->topo_sort();
    std::map<Node*, double> dist = {};
    std::map<Node*, Node*> prev = {};
    LOG4("Topological Sort:");
    for (auto n : topo) {
      LOG4("   " << n->unique_id_);
      dist.emplace(n, NINF);
      prev.emplace(n, nullptr);
    }

    std::set<int> stages_in;
    dist[graph->get_root()] = 0.0;
    Node *prev_node = nullptr;

    for (auto n : topo) {
      prev_node = n;
      LOG4("Looking at " << n->unique_id_ << " with dist " << dist.at(n));
      if (dist.at(n) != NINF) {
        for (auto e : n->out_edges_) {
          for (auto c : e->child_nodes_) {
            double wt = 0.0;
            // $root and END will not appear in this map.
            if (table_memory_access_.find(n->unique_id_) != table_memory_access_.end()) {
              auto pma = table_memory_access_.at(n->unique_id_);
              wt = pma.compute_table_power(Device::numPipes());
            }
            double new_wt = dist.at(n) + wt;
            LOG4(" child is " << c->unique_id_);
            if (dist.at(c) < new_wt) {
              dist[c] = new_wt;
              prev[c] = n;
              LOG4("  set prev of " << c->unique_id_ << " to be " << n->unique_id_);
            }
    } } } }

    double worst_power = 0.0;
    if (prev_node != nullptr) {
      worst_power = dist.at(prev_node);
    }
    LOG4("Worst case table path:");
    std::set<Node*> in_path;
    while (prev_node != nullptr) {
      LOG4("  " << prev_node->unique_id_);
      if (in_path.count(prev_node)) {
        LOG4("  table seen again?  " << prev_node->unique_id_);
        break; }  // avoid infinite loop
      in_path.insert(prev_node);
      on_critical_path_.emplace(prev_node->unique_id_, true);
      if (mau_features_->table_to_stage_.find(prev_node->unique_id_) !=
          mau_features_->table_to_stage_.end())
        stages_in.insert(mau_features_->table_to_stage_.at(prev_node->unique_id_));
      prev_node = prev.at(prev_node);
    }

    // For Tofino, add all tables in a stage when it is action dependent or
    // concurrent with the previous stage.
    for (int s=0; s < Device::numStages(); ++s) {
      mau_dep_t dep = mau_features_->get_dependency_for_gress_stage(g, s);
      if (dep != DEP_MATCH) {
        for (auto t : mau_features_->stage_to_tables_[g][s]) {
          if (on_critical_path_.find(t->unique_id()) == on_critical_path_.end()) {
            always_powered_on_.emplace(t->unique_id(), true);
            if (table_memory_access_.find(t->unique_id()) != table_memory_access_.end()) {
              auto pma = table_memory_access_.at(t->unique_id());
              worst_power += pma.compute_table_power(Device::numPipes());
      } } } }
    }

    auto& spec = Device::mauPowerSpec();
    int mau_latency = mau_features_->compute_pipe_latency(g);
    int deparser_scaling_starts_at = spec.get_deparser_throughput_scaling_starts();
    int power_scale_factor = 1.0;
    if (mau_latency > 0 && mau_latency > deparser_scaling_starts_at) {
      power_scale_factor =  spec.get_deparser_max_phv_valid() /
         (mau_latency + spec.get_pmarb_cycles_from_receive_credit_to_issue_phv_to_mau());
      LOG4("Pipeline latency scaling factor: " << float2str(power_scale_factor * 100.0) << "%");
    }
    worst_power *= power_scale_factor;
    LOG4("Worst case power for " << toString(g) << ": " << float2str(worst_power) << "W.");
    gress_powers_.emplace(g, worst_power);
  }

  double total_power = 0.0;
  for (auto p : gress_powers_) {
    total_power += p.second;
  }
  LOG4("Total estimated power: " << total_power << " W.");
  return total_power;
}

/**
  * To find the worst-case path, perform a post-order traversal of the
  * control flow graph, adding the outgoing edge for a node that results
  * in the highest estimated power.  Since an 'edge' for Tofino2 could invoke
  * multiple next tables (e.g. via long branches), an edge may indicate
  * to perform lookups on multiple tables.
  * On the worst path found, we also have to turn on any tables
  * in action-dependent stages based on the MPR settings.
  * We also have to add in any 'always run' tables, again based on MPR settings.
  */
double WalkPowerGraph::estimate_power_non_tofino() {
  for (gress_t g : Device::allGresses()) {
    // Find worst case table control flow.
    SimplePowerGraph *graph = graphs_->get_graph(g);
    std::set<Node*> worst_tbls;
    double worst_power = graph->get_tables_on_worst_path(table_memory_access_, worst_tbls);
    LOG4("Tables on worst case path: " << worst_tbls.size());
    for (auto t : worst_tbls) {
      LOG4("  " << t->unique_id_);
      on_critical_path_.emplace(t->unique_id_, true);
    }

    // Add in always-run tables.
    LOG4("Always on tables:");
    bool log_it = false;
    for (int s=0; s < Device::numStages(); ++s) {
      int active = mpr_settings_.at(g)->get_mpr_always_run_for_stage(s);
      for (auto t : mau_features_->stage_to_tables_[g][s]) {
        if (!t->logical_id) continue;
        int lid = *t->logical_id;
        if (active & (1 << lid)) {
          LOG4("  " << t->unique_id());
          log_it = true;
          always_powered_on_.emplace(t->unique_id(), true);
          if (on_critical_path_.find(t->unique_id()) == on_critical_path_.end()) {
            // only add memory contribution if not already considered on critical path
            if (table_memory_access_.find(t->unique_id()) != table_memory_access_.end()) {
              auto pma = table_memory_access_.at(t->unique_id());
              worst_power += pma.compute_table_power(Device::numPipes());
    } } } } }
    if (!log_it)
      LOG4("  None");

    // Add in tables that are turned on in action-dependent stages that may not
    // be on the critical path, by checking MPR settings.
    LOG4("Action-dependent powered-on tables:");
    log_it = false;
    for (int s=0; s < Device::numStages(); ++s) {
      mau_dep_t dep = mau_features_->get_dependency_for_gress_stage(g, s);
      if (dep == DEP_MATCH)
        continue;
      for (auto t : mau_features_->stage_to_tables_[g][s]) {
        if (is_mpr_powered_on(g, s, t)) {
            // only add memory contribution once
          if (on_critical_path_.find(t->unique_id()) == on_critical_path_.end() &&
              always_powered_on_.find(t->unique_id()) == always_powered_on_.end()) {
            LOG4("  " << t->unique_id());
            log_it = true;
            always_powered_on_.emplace(t->unique_id(), true);
            if (table_memory_access_.find(t->unique_id()) != table_memory_access_.end()) {
              auto pma = table_memory_access_.at(t->unique_id());
              worst_power += pma.compute_table_power(Device::numPipes());
    } } } } }
    if (!log_it)
      LOG4("  None");

    // Add in tables according to JBAY-2889 JIRA.
    // The crux of the problem for JBAY-A0:
    // When the next MAU stage for both ingress/ghost and egress is match
    // dependent, if the MAU stage latency differs across threads, a missing
    // AND gate can trigger spurious match look-ups.
    // From the JIRA description:
    //     "... then the mpr_glob_exec and mpr_long_brch outputs can't be trusted.
    //      Any table enabled by either of those predication paths, under the
    //      above conditions, must be considered to always run for compiler power
    //      consumption calculation."
    // This has not been fixed in B0, and it has *not* been fixed in CloudBreak yet! :(
    // The following if is irrelevant within this function, but I'm hopeful this
    // issue will be fixed for CloudBreak.
    if (Device::currentDevice() != Device::TOFINO) {
      for (int s=0; s < Device::numStages(); ++s) {
        mau_dep_t next_i_dep = DEP_MATCH;  // last stage considers "next stage" as
        mau_dep_t next_e_dep = DEP_MATCH;  // match dependent
        if (s != (Device::numStages() - 1)) {
          next_i_dep = mau_features_->get_dependency_for_gress_stage(INGRESS, s + 1);
          next_e_dep = mau_features_->get_dependency_for_gress_stage(EGRESS, s + 1); }
        if (next_i_dep == next_e_dep && next_i_dep == DEP_MATCH) {
          int i_lat = mau_features_->compute_stage_latency(INGRESS, s);  // current stage
          int e_lat = mau_features_->compute_stage_latency(EGRESS, s);  // current stage
          if (i_lat != e_lat) {
            LOG4("Since threads in MAU stage " << s << " have different latencies"
                 << " and their next stage is match dependent, have to consider"
                 << " tables in each thread as powered on for estimation purposes.");
            LOG4("  ingress latency is " << i_lat);
            LOG4("  egress latency is " << e_lat);
            for (auto t : mau_features_->stage_to_tables_[g][s]) {
              // Make sure do not double count the table.
              if (on_critical_path_.find(t->unique_id()) == on_critical_path_.end() &&
                  always_powered_on_.find(t->unique_id()) == always_powered_on_.end()) {
                LOG4("  " << t->unique_id() << " has to be considered always run.");
                always_powered_on_.emplace(t->unique_id(), true);
                if (table_memory_access_.find(t->unique_id()) != table_memory_access_.end()) {
                  auto pma = table_memory_access_.at(t->unique_id());
                  worst_power += pma.compute_table_power(Device::numPipes());
    } } } } } } }

    // Note: No anticipated pipeline scaling factor, as of yet (e.g. from the deparser.)
    LOG4("Worst case power for " << toString(g) << ": " << float2str(worst_power) << "W.");
    gress_powers_.emplace(g, worst_power);
  }
  double total_power = 0.0;
  for (auto p : gress_powers_) {
    total_power += p.second;
  }
  LOG4("Total estimated power: " << float2str(total_power) << " W.");
  return total_power;
}

/**
  * This function determines if a table in an action-dependent MAU stage will
  * be turned on, based on the worst-case power table control flow.
  * A table will be turned on if a table in the previous match dependent stage
  * will require it to be turned on.
  */
bool
WalkPowerGraph::is_mpr_powered_on(gress_t gress, int stage, const IR::MAU::Table* table) const {
  int last_match_dep_stage = mpr_settings_.at(gress)->get_mpr_stage(stage);
  if (stage == last_match_dep_stage)  // Function cannot be called when already match-dependent.
    return false;

  if (!table->logical_id) return false;

  for (auto pt : mau_features_->stage_to_tables_[gress][last_match_dep_stage]) {
    if (!pt->logical_id) continue;
    if (on_critical_path_.find(pt->unique_id()) == on_critical_path_.end() &&
        always_powered_on_.find(pt->unique_id()) == always_powered_on_.end()) {
      int prev_lt = *pt->logical_id;
      int nt_active = mpr_settings_.at(gress)->get_mpr_next_table(stage, prev_lt);
      int glob_active = mpr_settings_.at(gress)->get_mpr_global_exec(stage, prev_lt);
      // Long branches are currently set to always run for this scenario.

      int cur_lt = *table->logical_id % Memories::LOGICAL_TABLES;
      if (nt_active & (1 << cur_lt))
        return true;
      if (glob_active & (1 << cur_lt))
        return true;
  } }
  return false;
}

void WalkPowerGraph::create_mau_power_log(const IR::Node *root) const {
  if (!options_.display_power_budget) {
    return; }
  std::ofstream myfile;
  auto logDir = BFNContext::get().getOutputDirectory("logs", root->to<IR::BFN::Pipe>()->id);
  if (logDir) {
    myfile.open(Util::PathName(logDir).join("mau.power.log").toString());
    myfile << "+-----------------------------------------------------------+";
    myfile << std::endl;
    myfile << "|  Compiler version: " << BF_P4C_VERSION;
    myfile << std::endl;

    const time_t now = time(NULL);
    char build_date[1024];
    strftime(build_date, 1024, "%c", localtime(&now));

    myfile << "|  Created: " << build_date;
    myfile << std::endl;
    myfile << "|  Run ID: " << RunId::getId().c_str();
    myfile << std::endl;
    myfile << "+-----------------------------------------------------------+";
    myfile << std::endl << std::endl;

    print_features(myfile);
    print_latency(myfile);
    if (Device::currentDevice() != Device::TOFINO)
      print_mpr_settings(myfile);
    print_worst_power(myfile);
    // myfile << printNormalizedWeights() << std::endl;
    myfile.close(); }
}

void WalkPowerGraph::create_mau_power_json(const IR::Node *root) {
  auto logDir = BFNContext::get().getOutputDirectory("logs", root->to<IR::BFN::Pipe>()->id);
  if (!logDir)
    return;
  cstring powerFile = logDir + "/power.json";
  logger_ = new PowerLogging(powerFile,
                             Logging::Logger::buildDate(),
                             BF_P4C_VERSION,
                             BackendOptions().programName + ".p4",
                             RunId::getId(),
                             "1.0.0");  // schema version

  produce_json_tables();
  produce_json_total_power(root->to<IR::BFN::Pipe>()->id);
  produce_json_stage_characteristics();
  produce_json_total_latency(root->to<IR::BFN::Pipe>()->id);
  logger_->log();
  delete logger_;

  Logging::Manifest &manifest = Logging::Manifest::getManifest();
  // relative path to the output directory
  manifest.addLog(root->to<IR::BFN::Pipe>()->id, "power", "power.json");
}

void WalkPowerGraph::print_features(std::ofstream& out) const {
  for (gress_t g : Device::allGresses()) {
    mau_features_->print_features(out, g); }
  out << std::endl;
}

void WalkPowerGraph::print_latency(std::ofstream& out) const {
  for (gress_t g : Device::allGresses()) {
    mau_features_->print_latency(out, g); }
  out << std::endl;
}

void WalkPowerGraph::print_mpr_settings(std::ofstream& out) const {
  if (disable_mpr_config_) {
    out << "User disabled MPR configuration." << std::endl;
    out << "All tables will be powered on." << std::endl;
  }
  for (gress_t g : Device::allGresses()) {
    out << *mpr_settings_.at(g) << std::endl; }
  out << std::endl;
}

/**
  * Prints worst-case MAU power estimate per stage.
  * For example:
  Worst case ingress table flow
  ------------------------------------------------------------------------------
  |   Stage  |  Table Name  |   Always Run   |     Weight     |   Percentage   |
  ------------------------------------------------------------------------------
  |     0    |     it2_0    |       No       |      64.61     |     100.00%    |
  |          |              |                |                |                |
  |   Total  |              |                |      64.61     |      100%      |
  ------------------------------------------------------------------------------
  */
void WalkPowerGraph::print_worst_power(std::ofstream& out) const {
  std::map<gress_t, bool> has_always = {};

  // Sorting...
  std::map<gress_t, std::map<int, std::vector<UniqueId>>> in_stages;
  for (gress_t g : Device::allGresses()) {
    std::map<int, std::vector<UniqueId>> gm;
    for (int s=0; s < Device::numStages(); ++s) {
      std::vector<UniqueId> sm;
      gm.emplace(s, sm); }
    in_stages.emplace(g, gm);
    has_always.emplace(g, false);
  }

  for (auto map_vars : on_critical_path_) {
    UniqueId id = map_vars.first;
    bool on_path = map_vars.second;
    if (!on_path)
      continue;
    if (stages_.find(id) == stages_.end())
      continue;
    if (gress_map_.find(id) == gress_map_.end())
      continue;
    int stage_in = stages_.at(id);
    gress_t gr = gress_map_.at(id);
    in_stages[gr][stage_in].push_back(id);
  }
  for (auto map_vars : always_powered_on_) {
    UniqueId id = map_vars.first;
    bool on_path = map_vars.second;
    if (!on_path)
      continue;
    if (stages_.find(id) == stages_.end())
      continue;
    if (gress_map_.find(id) == gress_map_.end())
      continue;
    int stage_in = stages_.at(id);
    gress_t gr = gress_map_.at(id);
    bool found = false;
    for (auto look : in_stages[gr][stage_in]) {
      if (id == look) {
        found = true;
        break; } }
    if (!found) {
      in_stages[gr][stage_in].push_back(id);
      has_always[gr] |= true; }
  }

  // Printing...
  for (gress_t g : Device::allGresses()) {
    out << std::endl << "Worst case " << toString(g) << " table flow" << std::endl;
    std::stringstream heading;
    std::stringstream sep;
    size_t dashes = longest_table_name_ + 68;
    for (size_t i = 0; i < dashes; i++)
      sep << "-";
    sep << std::endl;
    std::stringstream sl;
    sl << "%=" << (longest_table_name_ + 4) << "s";

    // Table columns
    heading << sep.str();
    heading << "|" << boost::format("%=10s") % "Stage"
      << "|" << boost::format(sl.str()) % "Table Name"
      << "|" << boost::format("%=16s") % "Always Run"
      << "|" << boost::format("%=16s") % "Weight"
      << "|" << boost::format("%=16s") % "Percentage"
      << "|" << std::endl;
    heading << sep.str();
    out << heading.str();

    double total_power = gress_powers_.at(g);
    PowerMemoryAccess dummy = PowerMemoryAccess();
    double total_weight = dummy.compute_table_weight(total_power, Device::numPipes());

    for (int stage=0; stage < Device::numStages(); ++stage) {
      for (UniqueId id : in_stages[g][stage]) {
        std::stringstream st, n, always, wt, pcent;
        st << boost::format("%2d") % stage;
        n << external_names_.at(id);
        if (always_powered_on_.find(id) != always_powered_on_.end()) {
          always << "Yes";
        } else {
          always << "No";
        }
        PowerMemoryAccess pma = table_memory_access_.at(id);
        double tpwr = pma.compute_table_power(Device::numPipes());
        double tweight = pma.compute_table_weight(tpwr, Device::numPipes());
        wt << float2str(tweight);
        if (total_weight > 0) {
          pcent << float2str(100.0 * tweight / total_weight);
        } else {
          pcent << "0";
        }
        pcent << "%";

        std::stringstream line;
        line << "|" << boost::format("%=10s") % st.str()
          << "|" << boost::format(sl.str()) % n.str()
          << "|" << boost::format("%=16s") % always.str()
          << "|" << boost::format("%=16s") % wt.str()
          << "|" << boost::format("%=16s") % pcent.str()
          << "|" << std::endl;

        out << line.str();
    } }

    std::stringstream itotal, itot_wt, blank;
    itot_wt << float2str(total_weight);
    itotal << "|" << boost::format("%=10s") % "Total"
      << "|" << boost::format(sl.str()) % " "
      << "|" << boost::format("%=16s") % " "
      << "|" << boost::format("%=16s") % itot_wt.str()
      << "|" << boost::format("%=16s") % "100%"
      << "|" << std::endl;

     blank << "|" << boost::format("%=10s") % " "
       << "|" << boost::format(sl.str()) % " "
       << "|" << boost::format("%=16s") % " "
       << "|" << boost::format("%=16s") % " "
       << "|" << boost::format("%=16s") % " "
       << "|" << std::endl;

    out << blank.str();
    out << itotal.str();
    out << sep.str();
    if (has_always.at(g) && Device::currentDevice() == Device::TOFINO) {
      out << "  * A 'Yes' value in the Always Run column indicates that a table, though not "
        << std::endl
        << "    on the critical path, could not be predicated off, since the stage it is "
        << std::endl
        << "    located in has a concurrent or action dependency to the previous stage."
        << std::endl << std::endl;
    }
    out << "Worst case power for " << toString(g) << ": " << float2str(total_power) << " W";
    out << std::endl << std::endl;
  }
  out << std::endl;

  double all_power = 0.0;
  for (auto p : gress_powers_) {
    all_power += p.second; }
  out << "Total worst case power: " << float2str(all_power) << " W" << std::endl;
}

void WalkPowerGraph::produce_json_tables() {
  using MatchTables = PowerLogging::MatchTables;
  using StageDetails = PowerLogging::StageDetails;

  // table name -> JSON dictionary for a table
  std::map<cstring, MatchTables*> tableJSONData = {};
  for (auto data : table_memory_access_) {
    auto uid = data.first;
    auto pma = data.second;

    MatchTables* tbl;
    cstring ext_name = external_names_.at(uid);
    if (tableJSONData.find(ext_name) != tableJSONData.end()) {
      tbl = tableJSONData.at(ext_name);
    } else {
      tbl = new MatchTables(std::string(toString(gress_map_.at(uid))),
                            std::string(ext_name));
      tableJSONData.emplace(ext_name, tbl);
    }
    bool crit = (on_critical_path_.find(uid) != on_critical_path_.end());
    bool always_on = (always_powered_on_.find(uid) != always_powered_on_.end());
    double pwr = pma.compute_table_power(Device::numPipes());
    auto *stageDetails = new StageDetails(always_on, crit, stages_.at(uid),
                                          pma.compute_table_weight(pwr, Device::numPipes()));
    pma.log_json_memories(stageDetails);
    tbl->append(stageDetails);
  }

  for (auto t : tableJSONData)
    logger_->append_tables(t.second);
}

void WalkPowerGraph::produce_json_total_power(int pipe_id) {
  using TotalPower = PowerLogging::Total_Power;
  for (gress_t g : Device::allGresses()) {
    std::string gr_str(toString(g));
    double gr_pwr = gress_powers_.at(g);
    auto tp = new TotalPower(gr_str, pipe_id, gr_pwr);
    logger_->append_total_power(tp);
  }
}

void WalkPowerGraph::produce_json_total_latency(int pipe_id) {
  using TotalLatency = PowerLogging::Total_Latency;
  for (gress_t g : Device::allGresses()) {
    std::string gr_str(toString(g));
    logger_->append_total_latency(new TotalLatency(gr_str,
                                                   mau_features_->compute_pipe_latency(g),
                                                   pipe_id));
  }
}

void WalkPowerGraph::produce_json_stage_characteristics() {
  for (gress_t g : Device::allGresses()) {
    mau_features_->log_json_stage_characteristics(g, logger_);
  }
}

};  // end namespace MauPower
