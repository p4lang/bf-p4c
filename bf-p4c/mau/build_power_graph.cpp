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
  switch (tbl->always_run) {
  case IR::MAU::AlwaysRun::TABLE:
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
    break;

  case IR::MAU::AlwaysRun::NONE:
    break;

  case IR::MAU::AlwaysRun::ACTION:
    return true;
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

ordered_set<UniqueId> BuildPowerGraph::next_for(const IR::MAU::Table *tbl, cstring what) const {
  return next_table_properties_->next_for(tbl, what);
}

};  // end namespace MauPower
