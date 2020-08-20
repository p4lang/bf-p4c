#ifndef BF_P4C_PHV_DUMP_TABLE_FLOW_GRAPH_H_
#define BF_P4C_PHV_DUMP_TABLE_FLOW_GRAPH_H_

#include "bf-p4c/mau/table_flow_graph.h"

struct DumpTableFlowGraph : public Visitor {
    const PhvInfo& phv;

    explicit DumpTableFlowGraph(const PhvInfo& p) : phv(p) { }

    struct CollectPhvReadsAndWrites : public Inspector {
        const PhvInfo& phv;
        explicit CollectPhvReadsAndWrites(const PhvInfo& p) : phv(p) { }

        std::set<const PHV::Field*> reads, writes;

        bool preorder(const IR::MAU::Table* tbl) override {
            return !tbl->is_a_gateway_table_only();
        }

        bool preorder(const IR::MAU::Instruction* inst) override {
            for (unsigned i = 0; i < inst->operands.size(); i++) {
                auto f = phv.field(inst->operands[i]);
                if (f) {
                    if (i)
                        reads.insert(f);
                    else
                        writes.insert(f);
                }
            }

            return false;
        }
    };

    struct PhvDetails : public FlowGraph::DumpTableDetails {
        const PhvInfo& phv;
        explicit PhvDetails(const PhvInfo& p) : phv(p) { }

        void dump(std::ostream &out, const IR::MAU::Table* tbl) const override {
            out << FlowGraph::viz_node_name(tbl) << " [ shape=record, style=\"filled\","
                << " fillcolor=cornsilk, label=\""
                << (tbl->is_a_gateway_table_only() ? tbl->gateway_cond  : tbl->name)
                << "\\l\\l" << std::endl;

            if (!tbl->match_key.empty()) {
                out << "M:\\l" << std::endl;
                for (auto m : tbl->match_key) {
                    auto f = phv.field(m->expr);
                    out << " " << stripThreadPrefix(f->name) << "\\l" << std::endl;
                }
                out << "\\l";
            }

            CollectPhvReadsAndWrites fields(phv);
            tbl->apply(fields);

            if (!fields.reads.empty()) {
                out << "R:\\l" << std::endl;
                for (auto r : fields.reads)
                    out << " " << stripThreadPrefix(r->name) << "\\l" << std::endl;
                out << "\\l";
            }

            if (!fields.writes.empty()) {
                out << "W:\\l" << std::endl;
                for (auto w : fields.writes)
                    out << " " << stripThreadPrefix(w->name) << "\\l" << std::endl;
            }

            out << " \"];" << std::endl;
        }
    };

    std::ofstream* open_file(gress_t gress, int pipe_id, cstring directory = "graphs") {
        auto outdir = BFNContext::get().getOutputDirectory(directory, pipe_id);
        if (!outdir)
            return nullptr;

        static int fid = 0;
        auto filepath = outdir + "/" + std::to_string(fid++) + "_" + "table_flow_graph"
            + "_" + ::toString(gress) + ".dot";

        return new std::ofstream(filepath);
    }

    const IR::Node *apply_visitor(const IR::Node *n, const char*) override { return n; }

    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = Visitor::init_apply(root);

        ordered_map<gress_t, FlowGraph> graphs;
        FindFlowGraphs ffg(graphs);
        root->apply(ffg);

        for (auto& kv : graphs) {
            auto fs = open_file(kv.first, root->to<IR::BFN::Pipe>()->id);
            kv.second.dump_viz(*fs, new PhvDetails(phv));
        }

        return rv;
    }
};

#endif /* BF_P4C_PHV_DUMP_TABLE_FLOW_GRAPH_H_ */
