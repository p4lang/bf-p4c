#include <sys/stat.h>
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/common/run_id.h"
#include "bf-p4c/mau/characterize_power.h"
#include "bf-p4c/logging/manifest.h"
#include "lib/json.h"
#include "lib/path.h"

Visitor::profile_t CharacterizePower::init_apply(const IR::Node *root) {
    root->apply(default_next_);  // setup default next data structure
    return MauInspector::init_apply(root);
}

void CharacterizePower::produce_json(const IR::Node *root) {
    auto logDir = BFNContext::get().getOutputDirectory("logs", root->to<IR::BFN::Pipe>()->id);
    if (!logDir)
        return;
    cstring powerFile = logDir + "/power.json";
    logger = new PowerLogging(powerFile,
                              Logging::Logger::buildDate(),
                              BF_P4C_VERSION,
                              BackendOptions().programName + ".p4",
                              RunId::getId(),
                              "1.0.0");  // schema version

    produce_json_tables();
    produce_json_total_power(root->to<IR::BFN::Pipe>()->id);
    produce_json_stage_characteristics();
    produce_json_total_latency(root->to<IR::BFN::Pipe>()->id);
    logger->log();
    delete logger;

    Logging::Manifest &manifest = Logging::Manifest::getManifest();
    // relative path to the output directory
    manifest.addLog(root->to<IR::BFN::Pipe>()->id, "power", "power.json");
}

void CharacterizePower::produce_json_tables() {
    using MatchTables = PowerLogging::MatchTables;
    using StageDetails = PowerLogging::StageDetails;

    // table name -> JSON dictionary for a table
    std::map<cstring, MatchTables *> tableJSONData = {};

    for (auto data : table_unique_id_to_power_summary_) {
        auto uid = data.first;
        auto pts = data.second;
        auto pma = table_memory_access.at(uid);

        MatchTables* tbl;
        if (tableJSONData.find(pts.table_name) != tableJSONData.end()) {
            tbl = tableJSONData.at(pts.table_name);
        } else {
            tbl = new MatchTables(std::string(table_unique_id_to_gress_.at(uid)),
                                  std::string(pts.table_name));
            tableJSONData.emplace(pts.table_name, tbl);
        }
        bool crit = (table_unique_id_to_on_critical_path_.find(uid) !=
                     table_unique_id_to_on_critical_path_.end());
        auto *stageDetails = new StageDetails(pts.always_run, crit, pts.stage,
                                              compute_table_power(pma));
        pma.getMemories(stageDetails);

        tbl->append(stageDetails);
    }

    for (auto t : tableJSONData)
        logger->append_tables(t.second);
}

void CharacterizePower::produce_json_total_power(int pipeId) {
    using TotalPower = PowerLogging::Total_Power;
    auto ingress = new TotalPower("ingress", pipeId, ingress_worst_power_);
    logger->append_total_power(ingress);
    auto egress = new TotalPower("egress", pipeId, egress_worst_power_);
    logger->append_total_power(egress);
}

void CharacterizePower::produce_json_stage_characteristics() {
    using StageChar = PowerLogging::StageCharacteristics;
    using Features = PowerLogging::Features;

    for (uint16_t stage = 0; stage < 2 * Device::numStages(); ++stage) {
        dep_t dep = stage_dependency_to_previous_.at(stage);
        uint16_t stage_latency = compute_stage_latency(stage);
        uint16_t pred_cycle = (has_tcam_.at(stage) || has_chained_feature(stage, HAS_TCAM))
                                ? (base_predication_delay_ + tcam_delay_)
                                : base_predication_delay_;
        uint16_t add_to_lat = stage_latency;

        auto d = "match";
        if (dep == DEP_CONCURRENT) {
            add_to_lat = concurrent_latency_contribution_;
            d = "concurrent";
        } else if (dep == DEP_ACTION) {
            add_to_lat = action_latency_contribution_;
            d = "action";
        }

        auto *featuresJ = new Features(has_exact_.at(stage),
                                       has_meter_lpf_or_wred_.at(stage),
                                       has_selector_.at(stage),
                                       has_stateful_.at(stage),
                                       has_stats_.at(stage),
                                       has_tcam_.at(stage),
                                       max_selector_words_.at(stage));

        bool ext = has_chained_feature(stage, HAS_EXACT) &&
           !stage_has_feature(stage, HAS_EXACT);
        bool tcm = has_chained_feature(stage, HAS_TCAM) &&
           !stage_has_feature(stage, HAS_TCAM);
        bool sts = has_chained_feature(stage, HAS_STATS) &&
           !stage_has_feature(stage, HAS_STATS);
        bool lpf = has_chained_feature(stage, HAS_LPF_OR_WRED) &&
           !stage_has_feature(stage, HAS_LPF_OR_WRED);
        bool sel = has_chained_feature(stage, HAS_SEL) &&
           !stage_has_feature(stage, HAS_SEL);
        bool stful = has_chained_feature(stage, HAS_STFUL) &&
           !stage_has_feature(stage, HAS_STFUL);

        auto *featuresBJ = new Features(ext, lpf, sel, stful, sts, tcm, 0);
        auto *stageJ = new StageChar(
            stage_latency,
            add_to_lat,
            d,
            featuresJ,
            featuresBJ,
            stage < Device::numStages() ? "ingress" : "egress",
            pred_cycle,
            stage % Device::numStages());

        logger->append_stage_characteristics(stageJ);
    }
}

void CharacterizePower::produce_json_total_latency(int pipeId) {
    // On Tofino, the corner turn between stages 5 and 6 is 4-cycles
    uint16_t ilat = mau_corner_turn_latency_;
    uint16_t elat = mau_corner_turn_latency_;

    for (uint16_t stage = 0; stage < 2 * Device::numStages(); ++stage) {
        dep_t dep = stage_dependency_to_previous_.at(stage);
        uint16_t stage_latency = compute_stage_latency(stage);
        uint16_t add_to_lat = stage_latency;

        if (dep == DEP_CONCURRENT) {
            add_to_lat = concurrent_latency_contribution_;
        } else if (dep == DEP_ACTION) {
            add_to_lat = action_latency_contribution_;
        }

        if (stage >= Device::numStages()) {
            elat += add_to_lat;
        } else {
            ilat += add_to_lat;
        }
    }

    using TotalLatency = PowerLogging::Total_Latency;
    logger->append_total_latency(new TotalLatency("ingress", ilat, pipeId));
    logger->append_total_latency(new TotalLatency("egress", elat, pipeId));
}

void CharacterizePower::PowerMemoryAccess::getMemories(PowerLogging::StageDetails *sd) const {
    using Memories = PowerLogging::StageDetails::Memories;
    if (ram_read > 0)
      sd->append(new Memories("read", "sram", ram_read));
    if (ram_write > 0)
      sd->append(new Memories("write", "sram", ram_write));
    if (tcam_read > 0)
      sd->append(new Memories("search", "tcam", tcam_read));
    if (map_ram_read > 0)
      sd->append(new Memories("read", "map_ram", map_ram_read));
    if (map_ram_write > 0)
      sd->append(new Memories("write", "map_ram", map_ram_write));
    if (deferred_ram_read > 0)
      sd->append(new Memories("read", "deferred_ram", deferred_ram_read));
    if (deferred_ram_write > 0)
      sd->append(new Memories("write", "deferred_ram", deferred_ram_write));
}

void CharacterizePower::end_apply(const IR::Node *root) {
    if (display_power_budget_) {
        std::ofstream myfile;
        auto logDir = BFNContext::get().getOutputDirectory("logs", root->to<IR::BFN::Pipe>()->id);
        if (logDir) {
          myfile.open(Util::PathName(logDir).join(logFileName_).toString());
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

          myfile << printFeatures() << std::endl;
          myfile << printLatency() << std::endl;
          myfile << printWorstPower() << std::endl;
          myfile << printNormalizedWeights() << std::endl;
          myfile.close();
        }
    }

      // Now that have table information need, can produce power.json file.
      produce_json(root);

      double eps = max_power_ / 104729.0;
      double total_power = ingress_worst_power_ + egress_worst_power_;
      LOG4("Worst case table power: " << float2str(total_power));

      if (total_power < (max_power_ + eps)) {
          // Power check successful
      } else {
          double excess = total_power - max_power_;
          std::string s = float2str(excess);
          std::string error_msg = "Power worst case estimated budget exceeded by " + s + "W.\n";
          error_msg += "Too many memories are accessed in the worst case table control flow.\n";
          error_msg += "Adding control flow conditions to separate large table execution ";
          error_msg += "and/or splitting large tables may help.\n";

#if BAREFOOT_INTERNAL
          if (no_power_check_ || (disable_power_check_ && excess < (excess_threshold_ + eps))) {
#else
          if (disable_power_check_ && excess < (excess_threshold_ + eps)) {
#endif
              std::string warn_msg = "Power check explicitly disabled.\n";
              warn_msg += "The generated binary can potentially cause the device to ";
              warn_msg += "exceed the published max power.\n";
              warn_msg += "Please make sure this profile is fully tested to confirm ";
              warn_msg += "system functionality under worst case conditions.\n";
              WARNING(warn_msg);
              WARNING(error_msg);
          } else {
              ::error("%s", error_msg);
          }
      }
}

bool CharacterizePower::preorder(const IR::BFN::Pipe *p) {
  LOG4("Working on pipe " << p->id);
  logFileName_ = "mau.power_pipe" + std::to_string(p->id) + ".log";
  ingress_root_ = nullptr;
  egress_root_ = nullptr;
  gress_to_graph_.emplace(INGRESS, new SimpleTableGraph("ingress"));
  gress_to_graph_.emplace(EGRESS, new SimpleTableGraph("egress"));
  gress_to_graph_.emplace(GHOST, new SimpleTableGraph("ghost"));
  return true;
}

void CharacterizePower::postorder(const IR::BFN::Pipe *) {
  // Propagate shared memory accesses to tables that they were not attached to.
  add_unattached_memory_accesses();

  SimpleTableGraph* i_graph = get_graph(INGRESS);
  SimpleTableGraph* e_graph = get_graph(EGRESS);

  if (ingress_root_ != nullptr) {
    if (table_to_attached_gateway.find(ingress_root_->unique_id()) !=
        table_to_attached_gateway.end()) {
        auto gw_uid = table_to_attached_gateway.at(ingress_root_->unique_id());
        i_graph->add_edge(i_graph->getRoot()->unique_id_, gw_uid, "");
    } else {
        i_graph->add_edge(i_graph->getRoot()->unique_id_, ingress_root_->unique_id(), "");
    }
  }
  if (egress_root_ != nullptr) {
    if (table_to_attached_gateway.find(egress_root_->unique_id()) !=
        table_to_attached_gateway.end()) {
        auto gw_uid = table_to_attached_gateway.at(egress_root_->unique_id());
        e_graph->add_edge(i_graph->getRoot()->unique_id_, gw_uid, "");
    } else {
        e_graph->add_edge(e_graph->getRoot()->unique_id_, egress_root_->unique_id(), "");
    }
  }

  std::vector<SimpleTableGraph*> graphs;
  graphs.push_back(i_graph);
  graphs.push_back(e_graph);
  double NINF = -(std::pow(2.0, 32) - 1);  // small enough for practical purposes
  uint16_t pipe = 0;

  for (auto g : graphs) {
      compute_stage_dependencies(pipe);  // must be called before compute latency
      if (display_power_budget_) {
        std::string fname = g->name_ + ".power.dot";
        g->to_dot(fname);
      }

      /* To find the worst-case path, first find the topological sort of
         the control flow graph, and then compute maximum distances to
         each node.  A topological sort ensures all parent nodes have been
         visited, so the worst case path to a given node will go through
         the worst-case path to any of its parents. */
      std::vector<SimpleTableNode*> topo = g->topo_sort();
      std::map<SimpleTableNode*, double> dist = {};
      std::map<SimpleTableNode*, SimpleTableNode*> prev = {};
      LOG4("Topological Sort:");
      for (auto n : topo) {
          LOG4("   " << n->unique_id_);
          dist.emplace(n, NINF);
          prev.emplace(n, nullptr);
      }

      dist[g->getRoot()] = 0.0;
      SimpleTableNode *prev_node = nullptr;

      for (auto n : topo) {
          prev_node = n;
          // LOG4("Looking at " << n->unique_id_ << " with dist " << dist.at(n));
          if (dist.at(n) != NINF) {
              for (auto c : n->children_) {
                  double wt = 0.0;
                  // $root and END will not appear in this map.
                  if (table_memory_access.find(n->unique_id_) != table_memory_access.end()) {
                      auto pma = table_memory_access.at(n->unique_id_);
                      wt = compute_table_power(pma);
                  }
                  double new_wt = dist.at(n) + wt;
                  if (dist.at(c) < new_wt) {
                      dist[c] = new_wt;
                      prev[c] = n;
                      // LOG4("  set prev of " << c->unique_id_ << " to be " << n->unique_id_);
                  }
              }
          }
      }

      double worst_power = 0.0;
      if (prev_node != nullptr) {
          worst_power = dist.at(prev_node);
      }

      LOG4("Worst case table path:");
      while (prev_node != nullptr) {
          if (pipe == 0) {
              ingress_worst_case_path_.push(prev_node->unique_id_);
          } else {
              egress_worst_case_path_.push(prev_node->unique_id_);
          }
          table_unique_id_to_on_critical_path_.emplace(prev_node->unique_id_, true);
          LOG4("  " << prev_node->unique_id_);
          prev_node = prev.at(prev_node);
      }

      uint16_t mau_latency = compute_pipe_latency(pipe);

      LOG4("MAU latency (cycles): " << mau_latency);
      double scale_factor = 1.0;

      // FIXME: Do not know yet whether deparser throughput scaling will apply
      // to devices other than Tofino.  Revisit once have devices in our lab.
      if (Device::currentDevice() == Device::TOFINO) {
        if (mau_latency > 0 && mau_latency > deparser_throughput_scaling_starts_) {
            scale_factor = deparser_max_phv_valid_ /
                           (mau_latency + pmarb_cycles_from_receive_credit_to_issue_phv_to_mau_);
            LOG4("Pipeline latency scaling factor: " << float2str(scale_factor * 100.0) << "%");
        }
      }

      worst_power *= scale_factor;
      LOG4("Worst case gress power: " << float2str(worst_power) << "W.");

      if (pipe == 0) {
          ingress_worst_power_ = worst_power;
      } else {
          egress_worst_power_ = worst_power;
      }

      ++pipe;
  }
}

bool CharacterizePower::preorder(const IR::MAU::Meter *m) {
    // All 'normal' meters have to run at EOP time on Tofino.
    bool runs_at_eop = m->color_output();
    bool is_lpf_or_wred = m->alu_output();
    auto tbl = findContext<IR::MAU::Table>();
    auto uniq_id = tbl->unique_id(m);
    meter_runs_at_eop.emplace(uniq_id, runs_at_eop);
    meter_is_lpf_or_wred.emplace(uniq_id, is_lpf_or_wred);
    return true;
}

bool CharacterizePower::preorder(const IR::MAU::Counter *c) {
    bool runs_at_eop = c->type == IR::MAU::DataAggregation::BYTES ||
                       c->type == IR::MAU::DataAggregation::BOTH;
    auto tbl = findContext<IR::MAU::Table>();
    auto uniq_id = tbl->unique_id(c);
    counter_runs_at_eop.emplace(uniq_id, runs_at_eop);
    return true;
}

bool CharacterizePower::preorder(const IR::MAU::Selector *sel) {
    auto tbl = findContext<IR::MAU::Table>();
    auto uniq_id = tbl->unique_id(sel);
    selector_group_size_.emplace(uniq_id, sel->max_pool_size);
    return true;
}

bool CharacterizePower::preorder(const IR::MAU::Table *t) {
    if (t->name.size() > longest_table_name_) {
        longest_table_name_ = t->name.size();
    }
    bool has_gateway = t->gateway_rows.size() > 0;
    if (has_gateway) {
        if (t->gateway_name) {
            UniqueId gw_uid;
            gw_uid.name = t->gateway_name;
            table_to_attached_gateway.emplace(t->unique_id(), gw_uid);
        }
    }
    return true;
}

void CharacterizePower::postorder(const IR::MAU::Table *t) {
    uint16_t logical_table_id = t->logical_id;
    uint16_t stage = getStage(logical_table_id, t->gress);
    stage_to_tables_[stage].push_back(t);
    auto my_unique_id = t->unique_id();
    table_unique_id_to_gress_.emplace(my_unique_id, toString(t->gress));

    // Sum up memory accesses of each type of resource
    // Note that this is the sum of all attached tables of each specfic type.
    // For example, if two meters are attached to a match table, the
    // meter_table power memory access will be the sum of both.
    PowerMemoryAccess match_table, action_data_table, stat_table;
    PowerMemoryAccess meter_table, stateful_table, selector_table;
    PowerMemoryAccess tind_table, idletime_table;

    // collect usage of match table and any attached tables
    // update some map that stores that info

    bool match_runs_at_eop = false;
    bool local_meter_runs_at_eop = false;
    bool have_meter_lpf_or_wred = false;

    for (auto &use : t->resources->memuse) {
        auto &mem = use.second;
        if (mem.type == Memories::Use::METER) {
            if (meter_runs_at_eop.find(use.first) != meter_runs_at_eop.end()) {
                 match_runs_at_eop |= meter_runs_at_eop.at(use.first);
                 local_meter_runs_at_eop |= meter_runs_at_eop.at(use.first);
            }
            if (meter_is_lpf_or_wred.find(use.first) != meter_is_lpf_or_wred.end()) {
                have_meter_lpf_or_wred = true;
            }
        } else if (mem.type == Memories::Use::COUNTER) {
            if (counter_runs_at_eop.find(use.first) != counter_runs_at_eop.end()) {
                match_runs_at_eop |= counter_runs_at_eop.at(use.first);
            }
        }
    }

    for (auto &use : t->resources->memuse) {
        auto &mem = use.second;
        uint16_t all_mems = 0;
        for (auto &r : mem.row) {
            all_mems += r.col.size();
        }

        if (mem.type == Memories::Use::TERNARY) {
            // All TCAMs are read for a lookup
            match_table.tcam_read += all_mems;
            has_tcam_[stage] = true;

        } else if (mem.type == Memories::Use::EXACT) {
            // One unit of depth in each way is accessed on a table read.
            // Total RAMs accessed will then be the sum of the widths of ways.
            uint16_t num_ways = 0;
            for (auto way : t->ways) {
                // LOG4("  exact match width = " << way.width);
                ++num_ways;
                match_table.ram_read += way.width;
            }
            has_exact_[stage] = true;
            // FIXME(mea): If this is a keyless table, compiler currently always
            // uses an exact match bus.  This would have to be changed
            // when that does.
        } else if (mem.type == Memories::Use::ATCAM) {
            // One unit of depth in each column is accessed on a table read.
            // Total RAMs accessed will then be the sum of the widths of columns.
            uint16_t col_ram_width = 0;
            uint16_t num_cols = 0;
            for (auto way : t->ways) {
                LOG4("  atcam match width = " << way.width);
                if (col_ram_width != 0) {
                  BUG_CHECK(way.width != col_ram_width, "ATCAM column widths do not match.");
                }
                col_ram_width = way.width;
            }

            for (auto mem_way : mem.ways) {
              ++num_cols;
            }

            match_table.ram_read += (col_ram_width * num_cols);
            has_exact_[stage] = true;

        } else if (mem.type == Memories::Use::TIND) {
            tind_table.ram_read += 1;

        } else if (mem.type == Memories::Use::ACTIONDATA) {
            uint16_t ram_width = (t->layout.action_data_bytes_in_table + 15) / 16;

            auto local_action_data_table = CharacterizePower::PowerMemoryAccess();
            local_action_data_table.ram_read += ram_width;
            action_data_table += local_action_data_table;
            attached_memory_usage.emplace(use.first, local_action_data_table);

        } else if (mem.type == Memories::Use::METER) {
            auto local_meter_table = CharacterizePower::PowerMemoryAccess();
            local_meter_table.ram_read += 1;  // Meters are only one ram wide
            local_meter_table.ram_write += 1;
            local_meter_table.map_ram_read += all_mems;  // All map rams read for synth-2-port
            local_meter_table.map_ram_write += 1;        // But only one written
            // if have color map rams, add that to map_rams_read / map_rams_write
            // All 'normal' meters run at EOP.
            // LPF/WRED do not run at EOP.
            if (local_meter_runs_at_eop) {
                local_meter_table.deferred_ram_read += 1;
                local_meter_table.deferred_ram_write += 1;

                // Since normal meters (color-based) can only run at EOP on Tofino,
                // this condition can be used to increment the map_ram used for
                // meter color.
                local_meter_table.map_ram_read += 1;
                local_meter_table.map_ram_write += 1;
            }
            meter_table += local_meter_table;
            attached_memory_usage.emplace(use.first, local_meter_table);
            if (have_meter_lpf_or_wred) {
               has_meter_lpf_or_wred_[stage] = true;
            }

        } else if (mem.type == Memories::Use::SELECTOR) {
            auto local_selector_table = CharacterizePower::PowerMemoryAccess();
            local_selector_table.ram_read += 1;  // Selectors are only one ram wide
            local_selector_table.ram_write += 1;
            local_selector_table.map_ram_read += all_mems;  // All map rams read for synth-2-port
            local_selector_table.map_ram_write += 1;        // But only one written

            selector_table += local_selector_table;
            attached_memory_usage.emplace(use.first, local_selector_table);
            has_selector_[stage] = true;

            uint16_t sel_words = 1;
            if (selector_group_size_.find(use.first) != selector_group_size_.end()) {
                int gsize = selector_group_size_.at(use.first) + 119;
                sel_words = gsize / 120;
            }
            max_selector_words_[stage] = std::max(max_selector_words_.at(stage), sel_words);

        } else if (mem.type == Memories::Use::STATEFUL) {
            if (t->get_attached(use.first)->use != IR::MAU::StatefulUse::NO_USE) {
                auto local_stateful_table = CharacterizePower::PowerMemoryAccess();
                local_stateful_table.ram_read += 1;  // Stateful are only one ram wide
                local_stateful_table.ram_write += 1;
                local_stateful_table.map_ram_read += all_mems;  // All maprams read for synth-2-port
                local_stateful_table.map_ram_write += 1;        // But only one written

                stateful_table += local_stateful_table;
                attached_memory_usage.emplace(use.first, local_stateful_table); }
            has_stateful_[stage] = true;

        } else if (mem.type == Memories::Use::COUNTER) {
            auto local_stat_table = CharacterizePower::PowerMemoryAccess();
            local_stat_table.ram_read += 1;  // Counters are only one ram wide
            local_stat_table.ram_write += 1;
            local_stat_table.map_ram_read += all_mems;  // All map rams read for synth-2-port
            local_stat_table.map_ram_write += 1;        // But only one written

            // Even if counter is packet-based, if there is a meter
            // attached to the match table that runs at EOP, this counter
            // will be setup to run at EOP as well.
            // I no longer remember why this is the case.
            // Something to do with a hardware constraint?
            if (match_runs_at_eop) {
                local_stat_table.deferred_ram_read += 1;
                local_stat_table.deferred_ram_write += 1;
            }

            stat_table += local_stat_table;
            attached_memory_usage.emplace(use.first, local_stat_table);
            has_stats_[stage] = true;

        } else if (mem.type == Memories::Use::IDLETIME) {
            idletime_table.ram_read += 1;  // only access and update one idletime
            idletime_table.ram_write += 1;
        }

        /*
         * Unattached memories means that this is a shared resource.
         * Tables that appear here do not appear in the current match
         * table's memuse.
         * This means we have to find how many resources are consumed
         * by the shared resource from the match table it has been
         * attached to.  The complication here is that the IR traversal
         * order does not guarantee that the table it is attached to is
         * visited first.
         * So, two options:
         * (1) traverse the IR twice.  On first pass, fill in what can.
         *     On second pass, fill in unattached.
         * (2) add helper pass to find unattached match table.
         * Option (2) was selected.
         */
        if (mem.unattached_tables.size() > 0) {
          match_tables_with_unattached.push_back(t);
        }
    }

    // Sum all memory accesses.
    CharacterizePower::PowerMemoryAccess memory_access = match_table + action_data_table;
    memory_access += stat_table;
    memory_access += meter_table;
    memory_access += stateful_table;
    memory_access += selector_table;
    memory_access += tind_table;
    memory_access += idletime_table;

    double table_power = compute_table_power(memory_access);
    double normalized_wt = compute_table_weight(table_power);

    LOG4("\nTable power = " << table_power << " Watts.");
    LOG4("Table normalized weight = " << normalized_wt << ".");
    LOG4("logical_id = " << logical_table_id << ".");
    LOG4("\n" << memory_access);

    table_memory_access.emplace(my_unique_id, memory_access);
    auto pwr_summary = PowerTableSummary(stage % Device::numStages(),
                                         false,
                                         normalized_wt,
                                         t->name);
    table_unique_id_to_power_summary_.emplace(my_unique_id, pwr_summary);
}


bool CharacterizePower::preorder(const IR::MAU::TableSeq *seq) {
    // LOG4("Pre order:");
    for (auto t : seq->tables) {
        if (t->gress == INGRESS && ingress_root_ == nullptr) {
           ingress_root_ = t;
        } else if (t->gress == EGRESS && egress_root_ == nullptr) {
          egress_root_ = t;
        }
        // LOG4("  " << t->name);
    }
    return true;
}

void CharacterizePower::postorder(const IR::MAU::TableSeq *seq) {
    for (auto t : seq->tables) {
        SimpleTableGraph* graph = get_graph(t->gress);
        // LOG4("  " << t->name);
        bool has_gateway = table_to_attached_gateway.find(t->unique_id()) !=
                           table_to_attached_gateway.end();

        // LOG4("  next:");
        if (has_gateway) {
            auto gw_uid = table_to_attached_gateway.at(t->unique_id());
            graph->add_edge(gw_uid, t->unique_id(), "");
        }

        for (auto n : t->next) {
          // LOG4("      n.first = " << n.first);
          auto def_next = next_for(t, n.first, default_next_);

          if (table_to_attached_gateway.find(def_next) != table_to_attached_gateway.end()) {
              // LOG4("         default_next (pre) = " << def_next);
              def_next = table_to_attached_gateway.at(def_next);
          }
          // LOG4("         default_next = " << def_next);

          if (has_gateway && (n.first == "$false")) {
            auto gw_uid = table_to_attached_gateway.at(t->unique_id());
            graph->add_edge(gw_uid, def_next, n.first);
          } else if (has_gateway && (n.first == "$true")) {
            auto gw_uid = table_to_attached_gateway.at(t->unique_id());
            graph->add_edge(gw_uid, def_next, n.first);
          } else {
            graph->add_edge(t->unique_id(), def_next, n.first);
          }
        }
        auto def_tbl_hit = next_for(t, "$default", default_next_);
        if (table_to_attached_gateway.find(def_tbl_hit) != table_to_attached_gateway.end()) {
            // LOG4("         default_tbl_hit (pre) = " << def_tbl_hit);
            def_tbl_hit = table_to_attached_gateway.at(def_tbl_hit);
        }
        // LOG4("     default_tbl_hit = " << def_tbl_hit);

        // floating gateway false condition
        if (t->gateway_rows.size() > 0 && !t->gateway_name) {
          graph->add_edge(t->unique_id(), def_tbl_hit, "false");
        } else {
          graph->add_edge(t->unique_id(), def_tbl_hit, "tbl-hit");
        }

        auto def_tbl_miss = next_for(t, "$miss", default_next_);
        if (table_to_attached_gateway.find(def_tbl_miss) != table_to_attached_gateway.end()) {
            // LOG4("         def_tbl_miss (pre) = " << def_tbl_miss);
            def_tbl_miss = table_to_attached_gateway.at(def_tbl_miss);
        }
        // LOG4("     default_tbl_miss = " << def_tbl_miss);
        graph->add_edge(t->unique_id(), def_tbl_miss, "tbl-miss");
    }
}

/* Computes the power consumed by a single table in one pipeline. */
double CharacterizePower::compute_table_power(CharacterizePower::PowerMemoryAccess mem_access) {
  double power = 0.0;
  power += (mem_access.ram_read * ram_read_power_);
  power += (mem_access.ram_write * ram_write_power_);
  power += (mem_access.tcam_read * tcam_read_power_);
  power += (mem_access.map_ram_read * map_ram_read_power_);
  power += (mem_access.map_ram_write * map_ram_write_power_);
  power += (mem_access.deferred_ram_read * deferred_ram_read_power_);
  power += (mem_access.deferred_ram_write * deferred_ram_write_power_);
  return pipes_in_use_ * power;  // Account for power in all pipes
}

/* Normalize power units to a unitless weight value. */
double CharacterizePower::compute_table_weight(double table_power_all_pipes) {
  if (min_power_access_ > 0) {  // This can be 0, since JBay power numbers unknown.
    double normalized_weight = table_power_all_pipes / min_power_access_;
    // Make normalized weight for single pipe.
    return normalized_weight / pipes_in_use_;
  }
  return 0.0;
}

void CharacterizePower::compute_stage_dependencies(uint16_t pipe) {
    // MAU stage 0 is match dependent
    stage_dependency_to_previous_[Device::numStages()*pipe] = DEP_MATCH;
    if (Device::currentDevice() == Device::TOFINO) {
      // Forced match dependency between stages 5 and 6 for Tofino.
      stage_dependency_to_previous_[Device::numStages()*pipe + Device::numStages() / 2] = DEP_MATCH;
    }

    for (auto tup : stage_to_tables_) {
      uint16_t stage = tup.first;
      auto vec = tup.second;

      if (stage < Device::numStages()) {
          LOG4("Tables in ingress stage " << stage << ":");
      } else {
          LOG4("Tables in egress stage " << (stage % Device::numStages()) << ":");
      }
      for (auto t : vec) {
          LOG4("   " << t->name);
      }
    }

    for (int st = 1; st < Device::numStages(); ++st) {
        uint16_t cur_stage = st + (pipe * Device::numStages());
        // LOG4("Working on stage " << cur_stage);

        int prev_st = st - 1;
        dep_t the_dep = DEP_ACTION;  // JBay has no concurrent dependency
        if (Device::currentDevice() == Device::TOFINO) {
            the_dep = DEP_CONCURRENT;
        }

        if (stage_to_tables_.find(cur_stage) != stage_to_tables_.end()) {
            auto cur_tables = stage_to_tables_.at(cur_stage);

            while (prev_st >= 0 && the_dep == DEP_CONCURRENT) {
                uint16_t prev_stage = prev_st + (pipe * Device::numStages());
                // LOG4("   looking at prev stage " << prev_st);

                if (stage_to_tables_.find(prev_stage) != stage_to_tables_.end()) {
                    auto prev_tables = stage_to_tables_.at(prev_stage);
                    for (auto c : cur_tables) {
                        for (auto p : prev_tables) {
                            auto graph_dep = dep_graph_.get_dependency(c, p);
                            if (graph_dep == DependencyGraph::IXBAR_READ) {
                                the_dep = DEP_MATCH;
                                break;
                            } else if (graph_dep == DependencyGraph::ACTION_READ ||
                                       graph_dep == DependencyGraph::OUTPUT) {
                                if (the_dep == DEP_CONCURRENT) {
                                    the_dep = DEP_ACTION;
                                }
                            }
                        }
                        if (the_dep == DEP_MATCH) {
                            break;
                        }
                    }
                }
                prev_st -= 1;
            }
            if (the_dep > stage_dependency_to_previous_.at(cur_stage)) {
              stage_dependency_to_previous_[cur_stage] = the_dep;
            }
        }
    }

    // Minimum latency required for egress pipeline on Tofino,
    // so convert stages to match-dependent if can.
    if (pipe == 1) {
      uint16_t st = 0;

      while (compute_pipe_latency(pipe) < minimum_egress_pipe_latency_ &&
             st < Device::numStages()) {
          dep_t dep = stage_dependency_to_previous_.at(st + Device::numStages());
          if (dep != DEP_MATCH) {
              stage_dependency_to_previous_[st + Device::numStages()] = DEP_MATCH;
          }
          st += 1;
      }
    }
}

uint16_t CharacterizePower::compute_pipe_latency(uint16_t pipe) {
    uint16_t lat = mau_corner_turn_latency_;

    for (uint16_t s = 0; s < Device::numStages(); ++s) {
        uint16_t stage = s + pipe * Device::numStages();

        dep_t dep = stage_dependency_to_previous_.at(stage);
        if (dep == DEP_CONCURRENT) {
            lat += concurrent_latency_contribution_;
        } else if (dep == DEP_ACTION) {
            lat += action_latency_contribution_;
        } else {
            lat += compute_stage_latency(stage);
        }
    }
    return lat;
}

bool CharacterizePower::stage_has_feature(uint16_t stage, stage_feature_t feature) {
  if (feature == HAS_EXACT && has_exact_.at(stage))
      return true;
  else if (feature == HAS_TCAM && has_tcam_.at(stage))
      return true;
  else if (feature == HAS_STATS && has_stats_.at(stage))
      return true;
  else if (feature == HAS_SEL && has_selector_.at(stage))
      return true;
  else if (feature == HAS_LPF_OR_WRED && has_meter_lpf_or_wred_.at(stage))
      return true;
  else if (feature == HAS_STFUL && has_stateful_.at(stage))
      return true;
  return false;
}

bool CharacterizePower::has_chained_feature(uint16_t stage, stage_feature_t feature) {
    // Look earlier in the chain.
    dep_t dep_to_prev = stage_dependency_to_previous_.at(stage);
    int look_stage = stage;
    while ((look_stage % Device::numStages()) > 0 && dep_to_prev != DEP_MATCH) {
        --look_stage;
        dep_to_prev = stage_dependency_to_previous_.at(look_stage);
        if (stage_has_feature(look_stage, feature))
            return true;
        // For latency reasons, say has TCAM if have wide selector.
        if (feature == HAS_TCAM && stage_has_feature(look_stage, HAS_SEL) &&
            max_selector_words_.at(look_stage) > 1)
            return true;
    }
    // Look later in the chain if are stages to look at.
    if ((stage % Device::numStages()) == (Device::numStages() - 1))
        return false;
    look_stage = stage + 1;
    while (true) {
       dep_to_prev = stage_dependency_to_previous_.at(look_stage);
       if (dep_to_prev == DEP_MATCH)
            break;
       if (stage_has_feature(look_stage, feature))
            return true;
      // If we're already at the last stage, terminate loop.
      if ((look_stage % Device::numStages()) == (Device::numStages() - 1)) {
          break; }
      ++look_stage;
    }
    return false;
}

uint16_t CharacterizePower::compute_stage_latency(uint16_t stage) {
    uint16_t lat = base_delay_;
    if (has_tcam_.at(stage) || max_selector_words_.at(stage) > 1) {
        lat += tcam_delay_;
    } else if (has_chained_feature(stage, HAS_TCAM)) {
        lat += tcam_delay_;
    }

    if (has_selector_.at(stage) || has_chained_feature(stage, HAS_SEL)) {
        lat += selector_delay_;
    } else {
        if (has_meter_lpf_or_wred_.at(stage) || has_chained_feature(stage, HAS_LPF_OR_WRED)) {
            lat += meter_lpf_delay_;
        } else if (has_stateful_.at(stage) || has_chained_feature(stage, HAS_STFUL)) {
            lat += stateful_delay_;
        }
    }
    return lat;
}

void CharacterizePower::add_unattached_memory_accesses() {
    // Need to loop over tables again, and find

    for (auto t : match_tables_with_unattached) {
        // LOG4("Table " << t->name << " has unattached.");
        auto my_unique_id = t->unique_id();

        auto tbl_memory_access = table_memory_access.at(my_unique_id);
        // LOG4("Memory access before\n" << tbl_memory_access);

        for (auto &use : t->resources->memuse) {
            auto &mem = use.second;

            // For each unattached table, lookup the memory use
            // that is pinned to the attached table name.
            for (auto &unattached : mem.unattached_tables) {
                // auto &attached_table_unique_id = unattached.first;
                auto &match_attached_to_unique_id = unattached.second;
                // LOG4("Unattached attached_table_unique_id = " << attached_table_unique_id);
                // LOG4("     match_attached_to_unique_id = " << match_attached_to_unique_id);

                if (attached_memory_usage.find(match_attached_to_unique_id) !=
                    attached_memory_usage.end()) {
                    auto attached_mem_access =
                      attached_memory_usage.at(match_attached_to_unique_id);
                    tbl_memory_access += attached_mem_access;
                    // LOG4("Found attached memory access\n" << attached_mem_access);
                } else {
                    WARNING("Unable to find shared resource memory usage for " << t->name << ".");
                }
            }
        }
        // LOG4("Memory access after\n" << tbl_memory_access);
    }
}

/**
  * Partially copied from asm_output.cpp, but modified to return a UniqueId.
  * There's probably a way to reference that function instead of copying it.
  */
UniqueId CharacterizePower::next_for(const IR::MAU::Table *tbl,
                                     cstring what,
                                     const DefaultNext &def) {
  if (what == "$miss") {
      cstring tns = "$try_next_stage";
      if (tbl->next.count(tns)) {
          if (!tbl->next.at(tns)->empty())
              return tbl->next.at(tns)->front()->unique_id();
      }
  }
  if (tbl->actions.count(what) && tbl->actions.at(what)->exitAction)
      return UniqueId("END");
  if (tbl->next.count(what)) {
      if (tbl->next.at(what) && !tbl->next.at(what)->empty())
          return tbl->next.at(what)->front()->unique_id();
  } else if (tbl->next.count("$default")) {
      if (!tbl->next.at("$default")->empty())
          return tbl->next.at("$default")->front()->unique_id();
  }
  return def.next_in_thread_uniq_id(tbl);
}

void SimpleTableNode::add_child(SimpleTableNode* child, cstring edge_name) {
    bool found = false;
    for (auto n : children_) {
        if (n->unique_id_ == child->unique_id_) {
            found = true;
            break;
        }
    }
    if (!found) {
       children_.push_back(child);
       edge_names_.emplace(child, edge_name);
    }
}

void SimpleTableNode::add_parent(SimpleTableNode* parent) {
    bool found = false;
    for (auto n : parents_) {
        if (n->unique_id_ == parent->unique_id_) {
            found = true;
            break;
        }
    }
    if (!found) {
       parents_.push_back(parent);
    }
}

SimpleTableGraph* CharacterizePower::get_graph(gress_t gress) {
    return gress_to_graph_.at(gress);
}

void SimpleTableGraph::add_edge(UniqueId parent, UniqueId child, cstring edge_name) {
  SimpleTableNode* parent_node;
  if (nodes_.find(parent) != nodes_.end()) {
      parent_node = nodes_.at(parent);
  } else {
      parent_node = new SimpleTableNode(parent, getNextID());
      nodes_.emplace(parent, parent_node);
  }

  SimpleTableNode* child_node;
  if (nodes_.find(child) != nodes_.end()) {
      child_node = nodes_.at(child);
  } else {
      child_node = new SimpleTableNode(child, getNextID());
      nodes_.emplace(child, child_node);
  }

  parent_node->add_child(child_node, edge_name);
  child_node->add_parent(parent_node);
  LOG4("Added edge from " << parent_node->unique_id_ << " to " << child_node->unique_id_);
}

/**
  * Outputs the final placed table control flow graphs to a .dot file.
  */
void SimpleTableGraph::to_dot(cstring filename) {
    std::ofstream myfile;
    myfile.open(filename);

    std::queue<SimpleTableNode*> queue;
    queue.push(getRoot());
    std::map<UniqueId, bool> visited = {};

    myfile << "digraph " << name_ << " {" << std::endl;

    while (!queue.empty()) {
        SimpleTableNode* cur = queue.front();
        queue.pop();
        if (visited.find(cur->unique_id_) != visited.end()) {  // already visited
           continue;
        }
        visited.emplace(cur->unique_id_, true);

        myfile << cur->id;
        myfile << " [label=\"" << cur->unique_id_ << "\"";
        myfile << " shape=box color=\"black\"];" << std::endl;

        for (auto &c : cur->children_) {
            if (visited.find(c->unique_id_) == visited.end()) {  // not found
                queue.push(c);
            }
            myfile << cur->id << "-> " << c->id;
            cstring ename = cur->edge_names_.at(c);
            if (ename == "$try_next_stage") {
                ename = "tbl-miss";
            } else if (ename == "$true") {
                ename = "true";
            } else if (ename == "$false") {
                ename = "false";
            }
            myfile << " [label=\"" << ename << "\" color=\"black\"];" << std::endl;
        }
    }
    myfile << "}" << std::endl;
    myfile.close();
}

/**
  * Topological visit of table control flow graph.
  */
void SimpleTableGraph::topo_visit(SimpleTableNode *node,
                                  std::stack<SimpleTableNode*> *stack,
                                  std::map<SimpleTableNode*,
                                  bool> *visited) {
    visited->emplace(node, true);
    for (auto c : node->children_) {
        if (visited->find(c) == visited->end()) {  // not visited
            topo_visit(c, stack, visited);
        }
    }
    stack->push(node);
}

/**
  * Returns a topological sorting of the graph.
  */
std::vector<SimpleTableNode*> SimpleTableGraph::topo_sort() {
    std::vector<SimpleTableNode*> topo;
    std::map<SimpleTableNode*, bool> visited = {};
    std::stack<SimpleTableNode*> stack;

    topo_visit(getRoot(), &stack, &visited);

    while (!stack.empty()) {
        auto n = stack.top();
        stack.pop();
        topo.push_back(n);
    }
    return topo;
}

/**
  * Helper function to output string representation of a double to
  * two decimal places.
  */
std::string CharacterizePower::float2str(double d) {
  std::ostringstream s;
  s << std::fixed;
  s << std::setprecision(2);
  s << d;
  return s.str();
}

/**
  * Produces a string representation of the MAU features in use per stage.
  * For example:
  Ingress MAU Features by Stage
  ------------------------------------------------------------------------------------------------------------------------
  |   Stage  |   Exact  |  Ternary |   Statistics   |      Meter     |    Selector    |    Stateful    |   Dependency   |
  |  Number  |          |          |                |   LPF or WRED  |   (max words)  |                |   to Previous  |
  ------------------------------------------------------------------------------------------------------------------------
  |     0    |    No    |    Yes   |       Yes      |       No       |     No (0)     |       No       |      match     |
  |     1    |    No    |    No    |       No       |       No       |     No (0)     |       No       |   concurrent   |
  |     2    |    No    |    No    |       No       |       No       |     No (0)     |       No       |   concurrent   |
  |     3    |    No    |    No    |       No       |       No       |     No (0)     |       No       |   concurrent   |
  |     4    |    No    |    No    |       No       |       No       |     No (0)     |       No       |   concurrent   |
  |     5    |    No    |    No    |       No       |       No       |     No (0)     |       No       |   concurrent   |
  |     6    |    No    |    No    |       No       |       No       |     No (0)     |       No       |      match     |
  |     7    |    No    |    No    |       No       |       No       |     No (0)     |       No       |   concurrent   |
  |     8    |    No    |    No    |       No       |       No       |     No (0)     |       No       |   concurrent   |
  |     9    |    No    |    No    |       No       |       No       |     No (0)     |       No       |   concurrent   |
  |    10    |    No    |    No    |       No       |       No       |     No (0)     |       No       |   concurrent   |
  |    11    |    No    |    No    |       No       |       No       |     No (0)     |       No       |   concurrent   |
  ------------------------------------------------------------------------------------------------------------------------
  */
cstring CharacterizePower::printFeatures() {
    std::stringstream heading;
    std::stringstream sep;
    for (size_t i = 0; i < 120; i++)
        sep << "-";
    sep << std::endl;

    // Table columns
    heading << sep.str();
    heading << "|" << boost::format("%=10s") % "Stage"
       << "|" << boost::format("%=10s") % "Exact"
       << "|" << boost::format("%=10s") % "Ternary"
       << "|" << boost::format("%=16s") % "Statistics"
       << "|" << boost::format("%=16s") % "Meter"
       << "|" << boost::format("%=16s") % "Selector"
       << "|" << boost::format("%=16s") % "Stateful"
       << "|" << boost::format("%=16s") % "Dependency"
       << "|" << std::endl;
    heading << "|" << boost::format("%=10s") % "Number"
          << "|" << boost::format("%=10s") % " "
          << "|" << boost::format("%=10s") % " "
          << "|" << boost::format("%=16s") % " "
          << "|" << boost::format("%=16s") % "LPF or WRED"
          << "|" << boost::format("%=16s") % "(max words)"
          << "|" << boost::format("%=16s") % " "
          << "|" << boost::format("%=16s") % "to Previous"
          << "|" << std::endl;

    heading << sep.str();

    std::stringstream itbl;
    std::stringstream etbl;

    for (uint16_t stage = 0; stage < 2 * Device::numStages(); ++stage) {
        std::stringstream st, ex, tern, stats, lpf, sel, stfl, deps;
        st << boost::format("%2d") % (stage % Device::numStages());
        if (has_exact_.at(stage)) { ex << "Yes"; } else { ex << "No"; }
        if (has_tcam_.at(stage)) { tern << "Yes"; } else { tern << "No"; }
        if (has_stats_.at(stage)) { stats << "Yes"; } else { stats << "No"; }
        if (has_meter_lpf_or_wred_.at(stage)) { lpf << "Yes"; } else { lpf << "No"; }
        if (has_selector_.at(stage)) {
            sel << "Yes (" << max_selector_words_.at(stage) << ")";
        } else {
            sel << "No (0)";
        }
        if (has_stateful_.at(stage)) { stfl << "Yes"; } else { stfl << "No"; }

        dep_t dep = stage_dependency_to_previous_.at(stage);
        if (dep == DEP_CONCURRENT) {
            deps << "concurrent";
        } else if (dep == DEP_ACTION) {
            deps << "action";
        } else {
            deps << "match";
        }

        std::stringstream line;
        line << "|" << boost::format("%=10s") % st.str()
           << "|" << boost::format("%=10s") % ex.str()
           << "|" << boost::format("%=10s") % tern.str()
           << "|" << boost::format("%=16s") % stats.str()
           << "|" << boost::format("%=16s") % lpf.str()
           << "|" << boost::format("%=16s") % sel.str()
           << "|" << boost::format("%=16s") % stfl.str()
           << "|" << boost::format("%=16s") % deps.str()
           << "|" << std::endl;

        if (stage >= Device::numStages()) {
            etbl << line.str();
        } else {
            itbl << line.str();
        }
    }

    std::stringstream ss;
    ss << "Ingress MAU Features by Stage" << std::endl;
    ss << heading.str();
    ss << itbl.str();
    ss << sep.str() << std::endl;

    ss << "Egress MAU Features by Stage" << std::endl;
    ss << heading.str();
    ss << etbl.str();
    ss << sep.str() << std::endl;

    return ss.str();
}

/**
  * Produces a string representation of the MAU latency per stage.
  * For example:
  Ingress MAU Latency
  ---------------------------------------------------------------------------
  |   Stage  |   Clock  |   Predication  |   Dependency   |   Cycles Add   |
  |  Number  |  Cycles  |      Cycle     |   to Previous  |   to Latency   |
  ---------------------------------------------------------------------------
  |     0    |    22    |       13       |      match     |       22       |
  |     1    |    20    |       11       |   concurrent   |        1       |
  |     2    |    20    |       11       |   concurrent   |        1       |
  |     3    |    20    |       11       |   concurrent   |        1       |
  |     4    |    20    |       11       |   concurrent   |        1       |
  |     5    |    20    |       11       |   concurrent   |        1       |
  |     6    |    20    |       11       |      match     |       20       |
  |     7    |    20    |       11       |   concurrent   |        1       |
  |     8    |    20    |       11       |   concurrent   |        1       |
  |     9    |    20    |       11       |   concurrent   |        1       |
  |    10    |    20    |       11       |   concurrent   |        1       |
  |    11    |    20    |       11       |   concurrent   |        1       |
  ---------------------------------------------------------------------------
  */
cstring CharacterizePower::printLatency() {
    std::stringstream heading;
    std::stringstream sep;
    for (size_t i = 0; i < 75; i++)
        sep << "-";
    sep << std::endl;

    // Table columns
    heading << sep.str();
    heading << "|" << boost::format("%=10s") % "Stage"
       << "|" << boost::format("%=10s") % "Clock"
       << "|" << boost::format("%=16s") % "Predication"
       << "|" << boost::format("%=16s") % "Dependency"
       << "|" << boost::format("%=16s") % "Cycles Add"
       << "|" << std::endl;
       heading << "|" << boost::format("%=10s") % "Number"
          << "|" << boost::format("%=10s") % "Cycles"
          << "|" << boost::format("%=16s") % "Cycle"
          << "|" << boost::format("%=16s") % "to Previous"
          << "|" << boost::format("%=16s") % "to Latency"
          << "|" << std::endl;

    heading << sep.str();

    // On Tofino, the corner turn between stages 5 and 6 is 4-cycles
    uint16_t ilat = mau_corner_turn_latency_;
    uint16_t elat = mau_corner_turn_latency_;

    std::stringstream itbl;
    std::stringstream etbl;

    for (uint16_t stage = 0; stage < 2 * Device::numStages(); ++stage) {
        dep_t dep = stage_dependency_to_previous_.at(stage);
        uint16_t stage_latency = compute_stage_latency(stage);
        uint16_t pred_cycle = (has_tcam_.at(stage) || has_chained_feature(stage, HAS_TCAM))
                                ? (base_predication_delay_ + tcam_delay_)
                                : base_predication_delay_;
        uint16_t add_to_lat = stage_latency;

        std::stringstream st, clk, pred, deps, add;

        if (dep == DEP_CONCURRENT) {
            add_to_lat = concurrent_latency_contribution_;
        } else if (dep == DEP_ACTION) {
            add_to_lat = action_latency_contribution_;
        }
        deps << dep_to_name(dep);

        st << boost::format("%2d") % (stage % Device::numStages());
        clk << boost::format("%2d") % stage_latency;
        pred << boost::format("%2d") % pred_cycle;
        add << boost::format("%2d") % add_to_lat;

        std::stringstream line;
        line << "|" << boost::format("%=10s") % st.str()
             << "|" << boost::format("%=10s") % clk.str()
             << "|" << boost::format("%=16s") % pred.str()
             << "|" << boost::format("%=16s") % deps.str()
             << "|" << boost::format("%=16s") % add.str()
             << "|" << std::endl;

        if (stage >= Device::numStages()) {
            etbl << line.str();
            elat += add_to_lat;
        } else {
            itbl << line.str();
            ilat += add_to_lat;
        }
    }

    std::stringstream ss;
    ss << "Ingress MAU Latency" << std::endl;
    ss << heading.str();
    ss << itbl.str();
    ss << sep.str();
    ss << "Total latency for ingress: " << ilat << std::endl;
    ss << std::endl;

    ss << "Egress MAU Latency" << std::endl;
    ss << heading.str();
    ss << etbl.str();
    ss << sep.str();
    ss << "Total latency for egress: " << elat << std::endl;
    ss << std::endl;

    return ss.str();
  }

  /**
    * This is a debug function to make sure numbers matched Glass compiler.
    * Do not want to expose this information externally.
    */
  cstring CharacterizePower::printNormalizedWeights() {
      return "";
      /*
      if (min_power_access_ > 0) {
        std::stringstream s;

        s << "Normalized weights:" << std::endl;
        s << "   RAM Read: " << (ram_read_power_ / min_power_access_) << std::endl;
        s << "   RAM Write: " << (ram_write_power_ / min_power_access_) << std::endl;
        s << "   TCAM Read: " << (tcam_read_power_ / min_power_access_) << std::endl;

        s << "   MapRAM Read: " << (map_ram_read_power_ / min_power_access_) << std::endl;
        s << "   MapRAM Write: " << (map_ram_write_power_ / min_power_access_) << std::endl;

        s << "   Deferred RAM Read: " << (deferred_ram_read_power_ / min_power_access_) << std::endl;
        s << "   Deferred RAM Write: " << (deferred_ram_write_power_ / min_power_access_) << std::endl;

        return s.str();
     }
     return "";
     */
  }

  /**
    * Produces a string representation of the MAU latency per stage.
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
  cstring CharacterizePower::printWorstPower() {
      std::stringstream heading;
      std::stringstream sep;
      uint16_t dashes = longest_table_name_ + 68;
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

      std::stringstream itbl;
      std::stringstream etbl;

      std::vector<UniqueId> local_ingress_path;
      std::vector<UniqueId> ingress_always_on;
      std::vector<UniqueId> local_egress_path;
      std::vector<UniqueId> egress_always_on;
      double total_ingress_weight = 0.0;
      double total_egress_weight = 0.0;

      while (!ingress_worst_case_path_.empty()) {
        auto uniq_id = ingress_worst_case_path_.top();
        ingress_worst_case_path_.pop();
        if (table_unique_id_to_power_summary_.find(uniq_id) !=
            table_unique_id_to_power_summary_.end()) {
          auto pwr_summary = table_unique_id_to_power_summary_.at(uniq_id);
          if (pwr_summary.weight > 0) {
            total_ingress_weight += pwr_summary.weight;
            local_ingress_path.push_back(uniq_id);
          }
        }
      }

      for (uint16_t st = 0; st < Device::numStages(); ++st) {
          dep_t dep = stage_dependency_to_previous_.at(st);
          if (dep != DEP_MATCH) {
              if (stage_to_tables_.find(st) != stage_to_tables_.end()) {
                  for (auto t : stage_to_tables_.at(st)) {
                      bool found = false;
                      for (auto x : local_ingress_path) {
                          if (x == t->unique_id()) {
                              found = true;
                              break;
                          }
                      }
                      if (!found) {
                        if (table_unique_id_to_power_summary_.find(t->unique_id()) !=
                            table_unique_id_to_power_summary_.end()) {
                          auto pwr_summary = table_unique_id_to_power_summary_.at(t->unique_id());
                          if (pwr_summary.weight > 0) {
                            total_ingress_weight += pwr_summary.weight;
                            ingress_always_on.push_back(t->unique_id());
                          }
                        }
                      }
                  }
              }
          }
      }
      for (uint16_t st = Device::numStages(); st < (2 * Device::numStages()); ++st) {
          dep_t dep = stage_dependency_to_previous_.at(st);
          if (dep != DEP_MATCH) {
              if (stage_to_tables_.find(st) != stage_to_tables_.end()) {
                  for (auto t : stage_to_tables_.at(st)) {
                      bool found = false;
                      for (auto x : local_egress_path) {
                          if (x == t->unique_id()) {
                              found = true;
                              break;
                          }
                      }
                      if (!found) {
                          if (table_unique_id_to_power_summary_.find(t->unique_id()) !=
                              table_unique_id_to_power_summary_.end()) {
                            auto pwr_summary = table_unique_id_to_power_summary_.at(t->unique_id());
                            total_egress_weight += pwr_summary.weight;
                            egress_always_on.push_back(t->unique_id());
                          }
                      }
                  }
              }
          }
      }

      while (!egress_worst_case_path_.empty()) {
        auto uniq_id = egress_worst_case_path_.top();
        egress_worst_case_path_.pop();
        if (table_unique_id_to_power_summary_.find(uniq_id) !=
            table_unique_id_to_power_summary_.end()) {
          auto pwr_summary = table_unique_id_to_power_summary_.at(uniq_id);
          if (pwr_summary.weight > 0) {
            if (pwr_summary.weight > 0) {
              total_egress_weight += pwr_summary.weight;
              local_egress_path.push_back(uniq_id);
            }
          }
        }
      }

      /* ----------------------------------------
       * Ingress
       * ----------------------------------------*/
      for (auto uniq_id : local_ingress_path) {
        std::stringstream st, n, always, wt, pcent;
        auto pwr_summary = table_unique_id_to_power_summary_.at(uniq_id);
        st << boost::format("%2d") % pwr_summary.stage;
        n << uniq_id;
        if (pwr_summary.always_run) {
            always << "Yes";
        } else {
            always << "No";
        }
        wt << float2str(pwr_summary.weight);
        if (total_ingress_weight > 0) {
            pcent << float2str(100.0 * pwr_summary.weight / total_ingress_weight);
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

        itbl << line.str();
      }

      bool i_always = false;
      for (auto uniq_id : ingress_always_on) {
        i_always = true;
        std::stringstream st, n, always, wt, pcent;
        auto pwr_summary = table_unique_id_to_power_summary_.at(uniq_id);
        st << boost::format("%2d") % pwr_summary.stage;
        n << uniq_id;
        always << "Yes";
        wt << float2str(pwr_summary.weight);
        if (total_ingress_weight > 0) {
            pcent << float2str(100.0 * pwr_summary.weight / total_ingress_weight);
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

        itbl << line.str();
      }

      std::stringstream itotal, itot_wt, blank;
      itot_wt << float2str(total_ingress_weight);
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

      itbl << blank.str();
      itbl << itotal.str();

      std::stringstream ss;
      ss << "Worst case ingress table flow" << std::endl;
      ss << heading.str();
      ss << itbl.str();
      ss << sep.str();
      if (i_always) {
          ss << "  * A 'Yes' value in the Always Run column indicates that a table, though not "
             << std::endl
             << "    on the critical path, could not be predicated off, since the stage it is "
             << std::endl
             << "    located in has a concurrent or action dependency to the previous stage."
             << std::endl << std::endl;
      }
      ss << "Worst case power for ingress: " << float2str(ingress_worst_power_) << " W";
      ss << std::endl << std::endl;

      /* ----------------------------------------
       * Egress
       * ----------------------------------------*/
      for (auto uniq_id : local_egress_path) {
        std::stringstream st, n, always, wt, pcent;
        auto pwr_summary = table_unique_id_to_power_summary_.at(uniq_id);
        st << boost::format("%2d") % pwr_summary.stage;
        n << uniq_id;
        if (pwr_summary.always_run) {
            always << "Yes";
        } else {
            always << "No";
        }
        wt << float2str(pwr_summary.weight);
        if (total_egress_weight > 0) {
            pcent << float2str(100.0 * pwr_summary.weight / total_egress_weight);
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

        etbl << line.str();
      }

      bool e_always = false;
      for (auto uniq_id : egress_always_on) {
        e_always = true;
        std::stringstream st, n, always, wt, pcent;
        auto pwr_summary = table_unique_id_to_power_summary_.at(uniq_id);
        st << boost::format("%2d") % pwr_summary.stage;
        n << uniq_id;
        always << "Yes";
        wt << float2str(pwr_summary.weight);
        if (total_egress_weight > 0) {
            pcent << float2str(100.0 * pwr_summary.weight / total_egress_weight);
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

        etbl << line.str();
      }

      std::stringstream etotal, etot_wt;
      etot_wt << float2str(total_egress_weight);
      etotal << "|" << boost::format("%=10s") % "Total"
             << "|" << boost::format(sl.str()) % " "
             << "|" << boost::format("%=16s") % " "
             << "|" << boost::format("%=16s") % etot_wt.str()
             << "|" << boost::format("%=16s") % "100%"
             << "|" << std::endl;

      etbl << blank.str();
      etbl << etotal.str();

      ss << "Worst case egress table flow" << std::endl;
      ss << heading.str();
      ss << etbl.str();
      ss << sep.str();
      if (e_always) {
          ss << "  * A 'Yes' value in the Always Run column indicates that a table, though not "
             << std::endl
             << "    on the critical path, could not be predicated off, since the stage it is "
             << std::endl
             << "    located in has a concurrent or action dependency to the previous stage."
             << std::endl << std::endl;
      }
      ss << "Worst case power for egress: " << float2str(egress_worst_power_) << " W";
      ss << std::endl << std::endl << std::endl;

      ss << "Total worst case power: ";
      ss << float2str(ingress_worst_power_ + egress_worst_power_) << " W" << std::endl;
      ss << std::endl;

      return ss.str();
}
