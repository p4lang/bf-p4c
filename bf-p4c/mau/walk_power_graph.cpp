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
      compute_mpr(); }

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
  std::vector<gress_t> gr;
  get_gress_iterator(gr);
  for (auto g : gr) {
    mpr_settings_.emplace(g, new MprSettings(g)); }
}

void WalkPowerGraph::compute_mpr() {
  std::vector<gress_t> gr;
  get_gress_iterator(gr);

  if (next_table_properties_)
    LOG4("" << *next_table_properties_);

  for (gress_t g : gr) {
    MprSettings* mpr = mpr_settings_.at(g);
    SimplePowerGraph* graph = graphs_->get_graph(g);
    // Initialize MPR settings.
    int last_match_dep_stage = 0;
    // Keep track of what active long branch tags exit a given stage.
    // Map from stage to Map from tag ID to uniqueID that initiated it.
    std::map<int, std::map<int, UniqueId>> active_long_branch = {};

    // If a table is activated by a long branch, keep track of the long branch
    // tag ID and who initiated the long branch.
    std::map<UniqueId, std::set<std::pair<int, UniqueId>>> initiated_by = {};
    for (int s = 0; s < Device::numStages(); ++s) {
      std::map<int, UniqueId> exit_stage = {};
      std::vector<const IR::MAU::Table*> tables_in_stage;
      mau_features_->get_tables_in_gress_stage(g, s, tables_in_stage);
      // Setup what long branches are initiated at the end of each stage.
      for (auto t : tables_in_stage) {
        for (auto id_to_tag : next_table_properties_->long_branches(t->unique_id())) {
          // id_to_tag.first is long branch tag ID
          // id_to_tag.second is std::set<UniqueId>
          // map Long Branch Tag ID to logical table that initiated it
          exit_stage[id_to_tag.first] = t->unique_id();
          for (auto some_id : id_to_tag.second) {
            if (initiated_by.find(some_id) == initiated_by.end()) {
              std::set<std::pair<int, UniqueId>> tag_id;
              initiated_by.emplace(some_id, tag_id);
            }
            std::pair<int, UniqueId> ti = std::make_pair(id_to_tag.first, t->unique_id());
            initiated_by[some_id].insert(ti);
          }
        }
      }
      active_long_branch.emplace(s, exit_stage);
    }

    LOG4("Long branches per stage:");
    for (auto per_stage : active_long_branch) {
      LOG4("  Stage " << per_stage.first << ": ("
        << dep_to_name(mau_features_->get_dependency_for_gress_stage(g, per_stage.first))
        << ")");
      for (auto tags : per_stage.second) {
        LOG4("    Tag ID: " << tags.first << " initiated by " << tags.second);
    } }

    LOG4("Initiated by long branches:");
    for (auto some_id : initiated_by) {
      LOG4("  id " << some_id.first);
      std::pair<ssize_t, ssize_t> live_range =
        next_table_properties_->get_live_range_for_lb_with_dest(some_id.first);
      for (auto p : some_id.second) {
        LOG4("    tag " << p.first << " and id " << p.second); }
      if (live_range.first != -1 && live_range.second != -1) {
        LOG4("    tag live range: " << live_range.first << " to " << live_range.second); }
    }

    for (int s = 0; s < Device::numStages(); ++s) {
      if (disable_mpr_config_)
        break;  // set all tables to MPR always run instead

      // No need to initialize mpr_next_table_, mpr_global_exec_, mpr_long_branch_
      // Those are ready to go after object construction.
      std::vector<const IR::MAU::Table*> tables_in_stage;
      mau_features_->get_tables_in_gress_stage(g, s, tables_in_stage);
      if (s == 0) {  // stage 0 is special for MPR, everything is always_run
        int always_run = 0;
        for (auto tbl : tables_in_stage) {
          if (tbl->logical_id) always_run |= (1 << *tbl->logical_id); }
        mpr->set_mpr_always_run(s, always_run);
      } else {
        mau_dep_t dep = mau_features_->get_dependency_for_gress_stage(g, s);
        if (dep == DEP_MATCH)
          last_match_dep_stage = s;
        mpr->set_mpr_stage(s, last_match_dep_stage);

        std::vector<const IR::MAU::Table*> tables_prev;
        mau_features_->get_tables_in_gress_stage(g, last_match_dep_stage, tables_prev);

        // Knowing what is reachable now allows setting:
        // - mpr_next_table_ for local execute
        // - mpr_global_exec_ for global execute (one stage away)
        // - mpr_long_branch_ for long branches

        for (auto parent : tables_prev) {
          if (!parent->logical_id) continue;
          int active = 0;
          for (auto child : tables_in_stage) {
            if (!child->logical_id) continue;
            if (graph->can_reach(parent->unique_id(), child->unique_id())) {
              active |= (1 << *child->logical_id);
          } }
          mpr->set_mpr_next_table(s, *parent->logical_id, active);
        }

        // Global exec powers on tables in the current stage based on the
        // activation vector that is input.  To program this register,
        // find the logical tables in this current stage that could be activated
        // by global execute and then find what other tables in the current
        // stage could also be predicated on.
        // If the dependency is not match, check what tables can be activated
        // in the current stage based on any intermediate paths.
        // The lookup table (LUT) is indexed by the global execute bit that is
        // activated.  So, if bit[1] is activated in the vector, the LUT here
        // for entry 1 should power on whatever tables are reachable from
        // logical table 1 in the given stage.
        if (last_match_dep_stage != 0) {
          std::vector<const IR::MAU::Table*> tables_prev_minus_1;
          mau_features_->get_tables_in_gress_stage(g, last_match_dep_stage - 1,
                                                   tables_prev_minus_1);
          // Find which tables in this stage could be activated by global exec
          for (auto parent : tables_prev_minus_1) {
            for (auto child : tables_prev) {
              if (!child->logical_id) continue;
              if (graph->can_reach(parent->unique_id(), child->unique_id())) {
                // Since this 'child' table could be activated by global execute,
                // we now have to find what tables 'child' can reach in the current
                // stage.  This becomes the activation vector for this particular
                // execute bit.
                int exec_bit = *child->logical_id;
                int activate = 0;
                for (auto tbl_in_stage : tables_in_stage) {
                  if (!tbl_in_stage->logical_id) continue;
                  if (graph->can_reach(child->unique_id(), tbl_in_stage->unique_id())) {
                    activate |= (1 << *tbl_in_stage->logical_id);
                } }
                mpr->set_or_mpr_global_exec(s, exec_bit, activate);
                LOG5("Working on global exec bit in stage " << s);
                LOG5("  last_match_dep_stage is " << last_match_dep_stage);
                LOG5("  exec_bit is " << exec_bit);
                LOG5("  activate is " << activate);
          } } }
        } else {
          // When the last match dependency stage is 0, there has been no opportunity to set
          // any global execute bits that will be resolved.  As a result, all the tables
          // in stage 1 until the first match dependent stage will have to be set to mpr always run.
          int active = 0;
          for (auto cur : tables_in_stage) {
            if (!cur->logical_id) continue;
            if (cur->gress == g) {
              active |= (1 << *cur->logical_id);
              LOG4("Since the last match dependent stage is 0, no global execute bits will have"
                   << " been set and resolved.");
              LOG4("Setting " << cur->externalName() << " to always run.");
          } }
          mpr->set_or_mpr_always_run(s, active);
        }

        // Long branch activates tables two or more MAU stages away.
        // To set the long branch MPR configuration register,
        // find what long branch tags will have resolved upon entering
        // the current MAU stage.
        // If the dependency is not match, check what intermediate hops can
        // reach the current stage.
        for (auto tbl : tables_in_stage) {
          if (!tbl->logical_id) continue;
          if (initiated_by.find(tbl->unique_id()) != initiated_by.end()) {
            std::set<std::pair<int, UniqueId>> tags_and_ids = initiated_by.at(tbl->unique_id());
            LOG4("Table " << tbl->unique_id() << " is activated by:");
            for (auto p : tags_and_ids) {
              int active = 1 << *tbl->logical_id;
              LOG4("  tag " << p.first << " and initiated by id " << p.second);
              int initiated_in_stage = (mau_features_->table_to_stage_.at(p.second)) %
                                        Device::numStages();
              // If this initiated table can reach other tables in this stage, those
              // also have to be activated (either in the LUT or as part of always run).
              for (auto in_stage : tables_in_stage) {
                if (!in_stage->logical_id) continue;
                if (tbl->unique_id() == in_stage->unique_id()) {
                  continue; }
                if (graph->can_reach(tbl->unique_id(), in_stage->unique_id())) {
                  LOG4("  As a consequence, table " << in_stage->externalName()
                       << " also will be activated in the LUT.");
                  active |= (1 << *in_stage->logical_id);
              } }
              if (initiated_in_stage <= last_match_dep_stage) {
                mpr->set_or_mpr_long_branch(s, p.first, active);
              } else {
                // When long branch was initiated in a stage and there is no
                // match dependency separation, we have to figure out what the
                // last resolved long branch would be and find what intermediate
                // tables could have been run.
                // For now, just set tables that meet this criteria as always run.
                LOG4("Unable to resolve last match dependency long branch initiation.");
                LOG4("Setting " << tbl->externalName() << " to always run.");
                mpr->set_or_mpr_always_run(s, active);
              }
        } } }

        int always_run = 0;
        for (auto tbl : tables_in_stage) {
          if (!tbl->logical_id) continue;
          switch (tbl->always_run) {
          case IR::MAU::AlwaysRun::NONE:
          case IR::MAU::AlwaysRun::ACTION:
            continue;

          case IR::MAU::AlwaysRun::TABLE:
            LOG4("Table " << tbl->externalName() << " is marked as always run.");
            always_run |= (1 << *tbl->logical_id);
            // Unfortunately, the way we currently setup the predication path requires
            // any other tables reachable in the stage to also be set to always run,
            // because there will be no input pointer (next table, global exec, long branch)
            // to us for the MPR LUTs on input.
            for (auto tbl2 : tables_in_stage) {
              if (!tbl2->logical_id) continue;
              if (tbl->unique_id() == tbl2->unique_id()) {
                continue; }
              if (graph->can_reach(tbl->unique_id(), tbl2->unique_id())) {
                LOG4("  As a consequence, table " << tbl2->externalName()
                     << " also has to be set to always run.");
                always_run |= (1 << *tbl2->logical_id);
            } }
            break;
        } }
        mpr->set_or_mpr_always_run(s, always_run);
      }

      // Configure MPR bus dependency settings.
      if (s != (Device::numStages() - 1)) {
        mau_dep_t next_dep = mau_features_->get_dependency_for_gress_stage(g, s + 1);
        // Note, there is no need to pass along bus dependencies if there
        // are no more tables to program.
        // However, model asserts if next table is not passed through.  :(
        if (next_dep != DEP_MATCH) {
          // Next table bus dependency settings.
          mpr->set_mpr_bus_dep_next_table(s, true);
        }

        if (next_dep != DEP_MATCH && mau_features_->are_there_more_tables(g, s + 1)) {
          // Global execute bus dependency settings.
          int glob_active = 0;
          std::vector<const IR::MAU::Table*> tables_last_match_dep;
          mau_features_->get_tables_in_gress_stage(g, last_match_dep_stage,
                                                   tables_last_match_dep);
          // Pass through the global execute bits that would have last resolved.
          // Given that global execute is turning on tables in the next stage
          // (the stage that is action dependent), the configuration has to
          // reflect that the global execute bits in the last match dependent
          // stage are what has resolved (those tables are potentially turned on).
          for (auto some_tbl : tables_last_match_dep) {
            if (!some_tbl->logical_id) continue;
            glob_active |= (1 << *some_tbl->logical_id);
          }
          mpr->set_or_mpr_bus_dep_glob_exec(s, glob_active);

          // Long branch bus dependency settings.
          // Pass through the long branch Tag IDs that would have last resolved.
          for (auto some_id : initiated_by) {  // loop through all long branch destinations
            std::pair<ssize_t, ssize_t> live_range =
              next_table_properties_->get_live_range_for_lb_with_dest(some_id.first);
            std::set<std::pair<int, UniqueId>> tags_and_ids = initiated_by.at(some_id.first);
            // Tag ID is passed through iff tag is live in this stage, according to:
            //   live start <= stage < live end
            if (live_range.first != -1 && s >= live_range.first && s < live_range.second) {
              for (auto p : tags_and_ids) {
                LOG4("Tag ID: " << p.first);
                int initiated_in_stage = (mau_features_->table_to_stage_.at(p.second)) %
                                          Device::numStages();
                if (initiated_in_stage <= last_match_dep_stage) {
                  int lb_active = 1 << (p.first % Device::numLongBranchTags());
                  mpr->set_or_mpr_bus_dep_long_brch(s, lb_active);
                  LOG4("  Setting active : " << lb_active);
                } else {
                  // Tables on this long-branch path will have been set as always
                  // run, since the action-dependent chain will not be able to
                  // inject its update.
                  LOG4("  Unable to set mpr_bus_dep long_brch, since tag initiated in "
                    << initiated_in_stage << ", which is after the last match dependent "
                    << "stage of " << last_match_dep_stage);
          } } } }
        }  // next_dep != DEP_MATCH
      }  // s != last stage
    }  // stage

    // Bypass normal MPR config.
    if (disable_mpr_config_) {
      for (int s = 0; s < Device::numStages(); ++s) {
        mpr->set_mpr_stage(s, s);  // mpr stage doesn't matter when everything is always run
        std::vector<const IR::MAU::Table*> tables_in_stage;
        mau_features_->get_tables_in_gress_stage(g, s, tables_in_stage);
        int always_run = 0;
        for (auto tbl : tables_in_stage) {
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
        mpr->set_or_mpr_always_run(s, always_run);
        // MPR Bus dep still has to be programmed to avoid model asserts.
        if (s != (Device::numStages() - 1)) {
          mau_dep_t next_dep = mau_features_->get_dependency_for_gress_stage(g, s + 1);
          if (next_dep == DEP_ACTION) {  // model asserts if this is not passed through.
            // Next table
            mpr->set_mpr_bus_dep_next_table(s, true);
        } }
    } }
  }  // gress
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
  std::vector<gress_t> gr;
  get_gress_iterator(gr);
  for (gress_t g : gr) {
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
        std::vector<const IR::MAU::Table*> tbls;
        mau_features_->get_tables_in_gress_stage(g, s, tbls);
        for (auto t : tbls) {
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
  std::vector<gress_t> gr;
  get_gress_iterator(gr);
  for (auto g : gr) {
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
      std::vector<const IR::MAU::Table*> tbls;
      int active = mpr_settings_.at(g)->get_mpr_always_run_for_stage(s);
      mau_features_->get_tables_in_gress_stage(g, s, tbls);
      for (auto t : tbls) {
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
      std::vector<const IR::MAU::Table*> tbls;
      mau_features_->get_tables_in_gress_stage(g, s, tbls);
      for (auto t : tbls) {
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
            std::vector<const IR::MAU::Table*> tbls;
            mau_features_->get_tables_in_gress_stage(g, s, tbls);
            for (auto t : tbls) {
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

  std::vector<const IR::MAU::Table*> prev_tbls;
  mau_features_->get_tables_in_gress_stage(gress, last_match_dep_stage, prev_tbls);
  for (auto pt : prev_tbls) {
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
  std::vector<gress_t> gr;
  get_gress_iterator(gr);
  for (auto g : gr) {
    mau_features_->print_features(out, g); }
  out << std::endl;
}

void WalkPowerGraph::print_latency(std::ofstream& out) const {
  std::vector<gress_t> gr;
  get_gress_iterator(gr);
  for (auto g : gr) {
    mau_features_->print_latency(out, g); }
  out << std::endl;
}

void WalkPowerGraph::print_mpr_settings(std::ofstream& out) const {
  if (disable_mpr_config_) {
    out << "User disabled MPR configuration." << std::endl;
    out << "All tables will be powered on." << std::endl;
  }
  std::vector<gress_t> gr;
  get_gress_iterator(gr);
  for (auto g : gr) {
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
  std::vector<gress_t> gr;
  get_gress_iterator(gr);
  std::map<gress_t, bool> has_always = {};

  // Sorting...
  std::map<gress_t, std::map<int, std::vector<UniqueId>>> in_stages;
  for (auto g : gr) {
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
  for (auto g : gr) {
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
  std::vector<gress_t> gr;
  get_gress_iterator(gr);
  for (gress_t g : gr) {
    std::string gr_str(toString(g));
    double gr_pwr = gress_powers_.at(g);
    auto tp = new TotalPower(gr_str, pipe_id, gr_pwr);
    logger_->append_total_power(tp);
  }
}

void WalkPowerGraph::produce_json_total_latency(int pipe_id) {
  using TotalLatency = PowerLogging::Total_Latency;
  std::vector<gress_t> gr;
  get_gress_iterator(gr);
  for (gress_t g : gr) {
    std::string gr_str(toString(g));
    logger_->append_total_latency(new TotalLatency(gr_str,
                                                   mau_features_->compute_pipe_latency(g),
                                                   pipe_id));
  }
}

void WalkPowerGraph::produce_json_stage_characteristics() {
  std::vector<gress_t> gr;
  get_gress_iterator(gr);
  for (auto g : gr) {
    mau_features_->log_json_stage_characteristics(g, logger_);
  }
}

};  // end namespace MauPower
