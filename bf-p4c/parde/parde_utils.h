#ifndef EXTENSIONS_BF_P4C_PARDE_PARDE_UTILS_H_
#define EXTENSIONS_BF_P4C_PARDE_PARDE_UTILS_H_

#include <boost/algorithm/string.hpp>
#include <fstream>

#include "bf-p4c/parde/parser_info.h"

class DumpParser : public Visitor {
    cstring filename;
    std::stringstream out;
    bool detail = true;

 public:
    explicit DumpParser(cstring filename, bool detail = false)
        : filename(filename), detail(detail) {}

 private:
    static std::string escape(std::string s) {
        boost::replace_all(s, "ingress::", "");
        boost::replace_all(s, "egress::", "");
        boost::replace_all(s, "$", "\\$");
        boost::replace_all(s, ".", "\\.");
        boost::replace_all(s, "->", "-~");
        boost::replace_all(s, "<", "\\<");
        boost::replace_all(s, ">", "\\>");
        boost::replace_all(s, "-~", "->");
        return s;
    }

    static std::string to_label(std::string label, const void* what) {
        std::stringstream ss;
        ss << label << what;
        return ss.str();
    }

    void dump(const IR::BFN::Transition* transition) {
        out << "[ label=\"" << transition << "\" ]";
    }

    void dump(const IR::BFN::ParserState* state) {
        out << to_label("State", state) << " [shape=record";
        out << ", label=\"{";
        out << state->name << ":\\l\\l";

        if (detail) {
            for (auto stmt : state->statements)
                out << "    " << stmt << "\\l";

            out << "\\l";

            for (auto select : state->selects)
                out << "    " << select << "\\l";
        }

        out << "}\"";
        out << "];" << std::endl;
    }

    void dump(const IR::BFN::ParserGraph& graph, gress_t gress) {
        for (auto s : graph.states())
            dump(s);

        for (auto succ : graph.successors()) {
            for (auto dst : succ.second) {
                out << to_label("State", succ.first) << " -> "
                    << to_label("State", dst);

                if (detail)
                    dump(graph.transition(succ.first, dst));

                out << std::endl;
            }
        }

        for (auto &kv : graph.to_pipe()) {
            out << to_label("State", kv.first) << " -> "
                << ::toString(gress) << "_pipe";

            if (detail)
                dump(graph.to_pipe(kv.first));

            out << std::endl;
        }
    }

    void dump(const IR::BFN::LoweredParserState* state) {
        out << to_label("State", state) << " [shape=record, style=rounded";
        out << ", label=\"{";
        out << state->name << ":\\l\\l";

        if (detail) {
            if (!state->select->regs.empty())
                out << "    " << state->select << "\\l";
        }

        out << "}\"";
        out << "];" << std::endl;
    }

    void dump(const IR::BFN::LoweredParserMatch* match) {
        out << to_label("Match", match) << " [shape=record";
        out << ", label=\"{";
        out << "match " << match->value << ": \\l\\l";

        if (detail) {
            for (auto stmt : match->statements)
                out << "    " << stmt << "\\l";

            out << "\\l";

            for (auto save : match->saves)
                out << "    " << save << "\\l";

            out << "\\l";

            for (auto csum : match->checksums)
                out << "    " << csum << "\\l";

            out << "\\l shift: " << match->shift;
        }

        out << "}\"";
        out << "];" << std::endl;
    }

    void dump(const IR::BFN::LoweredParserGraph& graph, gress_t gress) {
        unsigned id = 0;
        for (auto s : graph.states()) {
            out << "subgraph cluster_" << id++ << " {";
            out << "style=invis;" << std::endl;

            dump(s);

            for (auto m : s->transitions)
                dump(m);

            out << "}" << std::endl;
        }

        for (auto s : graph.states()) {
            for (auto m : s->transitions) {
                out << to_label("State", s) << " -> "
                    << to_label("Match", m) << std::endl;

                if (m->next) {
                    out << to_label("Match", m) << " -> "
                        << to_label("State", m->next) << std::endl;
                } else {
                    out << to_label("Match", m) << " -> "
                        << ::toString(gress) << "_pipe" << std::endl;
                }
            }
        }
    }

    template <typename ParserGraphType>
    void dump_graph(const ParserGraphType& graph, gress_t gress) {
        out.str(std::string());

        out << "digraph parser {" << std::endl;
        out << "size=\"8,5\"" << std::endl;

        dump(graph, gress);

        out << "}" << std::endl;

        std::ofstream fs(filename + "_" + ::toString(gress) + ".dot");

        fs << escape(out.str());

        fs.close();
    }

    const IR::Node *apply_visitor(const IR::Node *n, const char*) override { return n; }

    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = Visitor::init_apply(root);

        CollectParserInfo cg;
        root->apply(cg);

        CollectLoweredParserInfo cgl;
        root->apply(cgl);

        if (!cg.graphs().empty() && !cgl.graphs().empty())
            BUG("IR is in an incoherent state");

        for (auto g : cg.graphs())
            dump_graph(*(g.second), (g.first)->gress);

        for (auto g : cgl.graphs())
            dump_graph(*(g.second), (g.first)->gress);

        return rv;
    }
};

#endif /* EXTENSIONS_BF_P4C_PARDE_PARDE_UTILS_H_ */
