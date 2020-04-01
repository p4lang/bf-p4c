#include "add_always_run.h"
#include "bf-p4c/common/empty_tableseq.h"

Visitor::profile_t AddAlwaysRun::AddTables::init_apply(const IR::Node* root) {
    auto result = MauTransform::init_apply(root);

    for (auto& gress_constraintMap : self.allTablesToAdd) {
        auto& gress = gress_constraintMap.first;
        auto& constraintMap = gress_constraintMap.second;

        // Get the flow graph for the current gress and populate an index of tables in the flow
        // graph by their unique ID.
        auto& flowGraph = self.flowGraphs[gress];
        std::map<UniqueId, const IR::MAU::Table*> tablesByUniqueId;
        for (auto* table : flowGraph.get_tables()) {
            tablesByUniqueId[table->pp_unique_id()] = table;
        }

        // Add tables to the flow graph.
        for (auto& table_constraints : constraintMap) {
            auto& table = table_constraints.first;
            auto& constraints = table_constraints.second;

            flowGraph.add_vertex(table);

            auto& tableIdsBefore = constraints.first;
            auto& tableIdsAfter = constraints.second;

            for (auto& beforeId : tableIdsBefore) {
                auto* beforeTable = tablesByUniqueId.at(beforeId);
                flowGraph.add_edge(beforeTable, table, "always_run");
            }

            for (auto& afterId : tableIdsAfter) {
                auto* afterTable = tablesByUniqueId.at(afterId);
                flowGraph.add_edge(table, afterTable, "always_run");
            }
        }

        // Do a topological sort of the flow graph to populate globalOrderings.
        int pos = 0;
        for (auto* table : flowGraph.topological_sort()) {
            globalOrderings[gress][table] = pos++;
        }
    }

    return result;
}

const IR::BFN::Pipe* AddAlwaysRun::AddTables::preorder(IR::BFN::Pipe* pipe) {
    // Override the behaviour for visiting pipes so that we accurately update tablesToAdd for each
    // gress.
    std::initializer_list<std::pair<const IR::MAU::TableSeq*&, gress_t>> threads = {
        {pipe->thread[0].mau, INGRESS},
        {pipe->thread[1].mau, EGRESS},
        {pipe->ghost_thread, GHOST},
    };
    for (auto& mau_gress : threads) {
        auto*& mau = mau_gress.first;
        auto gress = mau_gress.second;

        // Skip this gress if nothing to add.
        if (!globalOrderings.count(gress)) continue;

        // Populate tablesToAdd.
        for (auto& table_pos : globalOrderings.at(gress)) {
            auto* table = table_pos.first;
            if (self.allTablesToAdd.at(gress).count(table)) {
                tablesToAdd.push_back(table);
            }
        }

        // Visit the gress.
        visit(mau);
    }

    return pipe;
}

const IR::Node* AddAlwaysRun::AddTables::preorder(IR::MAU::TableSeq* tableSeq) {
    // Override the behaviour for visiting table sequences so that we accurately track
    // subsequentTable. This is also where we insert the always-run tables into the IR.
    prune();

    const auto* savedSubsequentTable = subsequentTable;

    // This will hold the result that we will use to overwrite the table sequence being visited.
    IR::Vector<IR::MAU::Table> result;

    for (unsigned i = 0; i < tableSeq->tables.size(); ++i) {
        // subsequentTable is the next table in the sequence.
        // If we're at the last table, then it's the one that we saved above.
        subsequentTable = i < tableSeq->tables.size() - 1 ? tableSeq->tables.at(i + 1)
                                                          : savedSubsequentTable;

        // Add to the result any tables that need to come before the current table.
        auto* curTable = tableSeq->tables[i];
        while (!tablesToAdd.empty() && compare(tablesToAdd.front(), curTable) < 0) {
            result.push_back(tablesToAdd.front());
            tablesToAdd.pop_front();
        }

        // Visit the current table. This mirrors the functionality in IR::Vector::visit_children.
        auto* rewritten = apply_visitor(curTable);
        if (!rewritten && curTable) {
            continue;
        } else if (rewritten == curTable) {
          result.push_back(curTable);
        } else if (auto l = dynamic_cast<const IR::Vector<IR::MAU::Table>*>(rewritten)) {
            result.append(*l);
        } else if (auto v = dynamic_cast<const IR::VectorBase*>(rewritten)) {
            if (v->empty()) continue;

            for (auto elt : *v) {
                if (auto e = dynamic_cast<const IR::MAU::Table*>(elt)) {
                    result.push_back(e);
                } else {
                    BUG("visitor returned invalid type %s for Vector<IR::MAU::Table>",
                        elt->node_type_name());
                }
            }
        } else if (auto e = dynamic_cast<const IR::MAU::Table*>(rewritten)) {
            result.push_back(e);
        } else {
            BUG("visitor returned invalid type %s for Vector<IR::MAU::Table>",
                rewritten->node_type_name());
        }
    }

    // Append to the result any tables that need to come before the subsequentTable.
    while (!tablesToAdd.empty() && compare(tablesToAdd.front(), subsequentTable) < 0) {
        result.push_back(tablesToAdd.front());
        tablesToAdd.pop_front();
    }

    tableSeq->tables = result;
    return tableSeq;
}

const IR::Node* AddAlwaysRun::AddTables::preorder(IR::MAU::Table* table) {
    // Ensure we revisit any table sequences that are shared across tables.
    revisit_visited();
    return table;
}

int AddAlwaysRun::AddTables::compare(const IR::MAU::Table* t1, const IR::MAU::Table* t2) const {
    if (t1 == t2) return 0;
    if (t1 == nullptr) return 1;
    if (t2 == nullptr) return -1;

    BUG_CHECK(t1->gress == t2->gress, "Attempted to compare tables from different gresses");
    BUG_CHECK(globalOrderings.count(t1->gress), "Global table ordering not available for %1%",
              t1->gress);

    auto globalOrdering = globalOrderings.at(t1->gress);
    BUG_CHECK(globalOrdering.count(t1), "Global ordering not available for table %1%", t1);
    BUG_CHECK(globalOrdering.count(t2), "Global ordering not available for table %1%", t2);

    return globalOrdering.at(t1) - globalOrdering.at(t2);
}

AddAlwaysRun::AddTables* AddAlwaysRun::AddTables::clone() const {
    return new AddTables(*this);
}

AddAlwaysRun::AddTables& AddAlwaysRun::AddTables::flow_clone() {
    return *clone();
}

void AddAlwaysRun::AddTables::flow_merge(Visitor& v_) {
    // Check that the other visitor agrees with this one on the tables that need to be added.
    AddTables& v = dynamic_cast<AddTables&>(v_);
    BUG_CHECK(tablesToAdd == v.tablesToAdd, "Inconsistent tables added on merging program paths");
}

AddAlwaysRun::AddAlwaysRun(const ordered_map<gress_t, ConstraintMap>& tablesToAdd) :
allTablesToAdd(tablesToAdd) {
    // Insert the requested tables into the IR as follows:
    //   0. Rewrite the IR to add empty table sequences for fall-through branches.
    //   1. Obtain a flow graph.
    //   2. Insert the requested tables into the flow graph according to the input constraints.
    //   3. Topologically sort the tables in the resulting graph to obtain a global ordering for
    //      all tables.
    //   4. Insert the tables into the IR so that all execution paths are consistent with the
    //      global ordering.
    addPasses({
        new AddEmptyTableSeqs(),
        new FindFlowGraphs(flowGraphs),
        new AddTables(*this),
    });
}
