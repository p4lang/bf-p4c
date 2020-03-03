#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/mau/build_power_graph.h"
#include "bf-p4c/mau/default_next.h"
#include "bf-p4c/mau/jbay_next_table.h"
#include "bf-p4c/mau/mau_power.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/simple_power_graph.h"
#include "ir/gress.h"
#include "lib/ordered_set.h"

namespace MauPower {

BuildPowerGraph::BuildPowerGraph(const NextTable* next_table_properties,
                                 const BFN_Options& options) :
  next_table_properties_(next_table_properties), options_(options) {
  ingress_graph_ = new SimplePowerGraph(toString(INGRESS));
  egress_graph_ = new SimplePowerGraph(toString(EGRESS));
  ghost_graph_ = new SimplePowerGraph(toString(GHOST));
  default_next_ = new DefaultNext(options.disable_long_branch);
}

SimplePowerGraph* BuildPowerGraph::get_graph(gress_t g) {
  if (g == EGRESS)
    return egress_graph_;
  else if (g == GHOST)
    return ghost_graph_;
  else
    return ingress_graph_;
}

Visitor::profile_t BuildPowerGraph::init_apply(const IR::Node *root) {
  root->apply(*default_next_);  // setup default next data structure
  return MauInspector::init_apply(root);
}

void BuildPowerGraph::end_apply(const IR::Node *root) {
  if (options_.debugInfo) {  // graph outputs
    std::vector<gress_t> gr;
    get_gress_iterator(gr);
    for (auto g : gr) {
      SimplePowerGraph* graph = get_graph(g);
      std::string fname = graph->name_ + ".power.dot";
      auto logDir = BFNContext::get().getOutputDirectory("graphs", root->to<IR::BFN::Pipe>()->id);
      if (logDir)
        fname = logDir + "/" + graph->name_ + ".power.dot";
      graph->to_dot(fname);
    }
  }
}

bool BuildPowerGraph::preorder(const IR::MAU::TableSeq *seq) {
  LOG4("\nTable seq");
  for (auto t : seq->tables) {
    LOG4("  t = " << t->externalName());
  }

  for (auto t : seq->tables) {
    SimplePowerGraph* graph = get_graph(t->gress);
    Node* root = graph->get_root();
    if (root->out_edges_.size() == 0) {
      ordered_set<UniqueId> activated;
      activated.insert(t->unique_id());
      graph->add_connection(root->unique_id_, activated, "$start");
      break;
    }
  }
  return true;
}

bool BuildPowerGraph::preorder(const IR::MAU::Table *tbl) {
  SimplePowerGraph* graph = get_graph(tbl->gress);
  LOG4("Table " << tbl->externalName());
  if (tbl->always_run) {
    LOG4("  always run!");
    if (always_run_.size() > 0) {
      UniqueId last = always_run_.back();
      std::vector<UniqueId> leaves;
      graph->get_leaves(last, leaves);
      for (auto u : leaves) {
        ordered_set<UniqueId> connect_always_run;
        connect_always_run.insert(tbl->unique_id());
        graph->add_connection(u, connect_always_run, "$always");
      }
    }
    always_run_.push_back(tbl->unique_id());
  }

  // Build connections by looking at action names, $hit, $miss, $try_next_stage, $default.
  LOG4("Actions:");
  for (auto a : tbl->actions) {
    ordered_set<UniqueId> next_edges = next_for(tbl, a.second->name.originalName);
    LOG4("  " << a.second->name.originalName << ": " << next_edges.size());
    for (auto u : next_edges)
      LOG4("    " << u);
    graph->add_connection(tbl->unique_id(), next_edges, a.second->name.originalName);
  }
  for (auto &line : tbl->gateway_rows) {
    if (line.second) {
      ordered_set<UniqueId> gw_edges = next_for(tbl, line.second);
      if (gw_edges.size() > 0) {
        LOG4("GW edge: " << line.second);
        for (auto g : gw_edges)
          LOG4("    " << g);
        graph->add_connection(tbl->unique_id(), gw_edges, line.second);
  } } }

  std::vector<cstring> edge_types;
  edge_types.push_back("$hit");
  edge_types.push_back("$miss");
  edge_types.push_back("$try_next_stage");
  edge_types.push_back("$default");

  for (cstring edge_name : edge_types) {
    ordered_set<UniqueId> found_edges = next_for(tbl, edge_name);
    if (found_edges.size() > 0) {
      LOG4(edge_name << ": " << found_edges.size());
      for (auto u : found_edges)
        LOG4("    " << u);
      graph->add_connection(tbl->unique_id(), found_edges, edge_name);
  } }
  return true;
}

BuildPowerGraph* BuildPowerGraph::clone() const {
  LOG5(" ------ clone ----- ");
  return new BuildPowerGraph(*this);
}
void BuildPowerGraph::flow_merge(Visitor& /* v */) {
  LOG5(" ------ merge ----- ");
  // nothing to do yet.
}


/**
  * Copied from asm_output.cpp, but replaced NextTableSet with ordered_set,
  * (NextTableSet is essentially a wrapper around that anyway.)
  * Refactor to eliminate duplicate code.
  */
ordered_set<UniqueId> BuildPowerGraph::next_for(const IR::MAU::Table *tbl, cstring what) const {
  if (what == "$miss" && tbl->next.count("$try_next_stage"))
    what = "$try_next_stage";

  ordered_set<UniqueId> rv;
  if (tbl->actions.count(what) && tbl->actions.at(what)->exitAction) {
    BUG_CHECK(!Device::numLongBranchTags() || options_.disable_long_branch,
              "long branch incompatible with exit action");
    return rv;  // empty set is fine
  }
  if (!tbl->next.count(what))
    what = "$default";
  if (tbl->next.count(what)) {
    // Tofino2 specific
    if (tbl->next.at(what) && next_table_properties_) {
      // We want to build this set according to the NextTableProp
      // Add tables according to next table propagation (if it has an entry in the map)
      if (next_table_properties_->props.count(tbl->unique_id())) {
        auto prop = next_table_properties_->props.at(tbl->unique_id());
        for (auto id : prop[what])
            rv.insert(id);
        // Add the run_if_ran set
        for (auto always : prop["$run_if_ran"])
            rv.insert(always);
        return rv; }
    }
    if (tbl->next.at(what) && !tbl->next.at(what)->empty()) {  // Tofino specific
      auto* nt = tbl->next.at(what)->front();
      if (nt)
        rv.insert(nt->unique_id());
      return rv;
    }
  }
  if (Device::numLongBranchTags() > 0 && !options_.disable_long_branch) {
    // Always add run_if_ran set
    if (next_table_properties_->props.count(tbl->unique_id())) {
      auto prop = next_table_properties_->props.at(tbl->unique_id());
      for (auto always : prop["$run_if_ran"])
          rv.insert(always);
    }
    return rv;
  }
  rv.insert(default_next_->next_in_thread_uniq_id(tbl));
  return rv;
}

};  // end namespace MauPower
