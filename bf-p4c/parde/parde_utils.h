#ifndef EXTENSIONS_BF_P4C_PARDE_PARDE_UTILS_H_
#define EXTENSIONS_BF_P4C_PARDE_PARDE_UTILS_H_

#include <sys/stat.h>
#include <boost/algorithm/string.hpp>
#include <fstream>

#include "bf-p4c/parde/parser_info.h"
#include "bf-p4c/bf-p4c-options.h"

class DumpParser : public Visitor {
    cstring filename;
    std::stringstream out;
    bool detail = true;

 public:
    explicit DumpParser(cstring filename, bool detail = false)
        : filename(filename), detail(detail || LOGGING(4)) {}

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
        out << to_label("State", state);
        out << " [shape=record, style=\"filled,rounded\", fillcolor=cornsilk";
        out << ", label=\"{";
        out << state->name << ":\\l\\l";

        if (detail) {
            for (auto stmt : state->statements)
                out << "    " << stmt << "\\l";

            if (state->statements.size())
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
        out << to_label("State", state) << " [style=filled, fillcolor=lightskyblue1, shape=record";
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
        out << to_label("Match", match) << " [style=filled, fillcolor=aliceblue, shape=record";
        out << ", label=\"{";
        out << "match " << match->value << ": \\l\\l";

        if (detail) {
            for (auto stmt : match->extracts)
                out << "    " << stmt << "\\l";

            if (match->extracts.size())
                out << "\\l";

            for (auto save : match->saves)
                out << "    " << save << "\\l";

            if (match->saves.size())
                out << "\\l";

            for (auto csum : match->checksums)
                out << "    " << csum << "\\l";

            if (match->checksums.size())
                out << "\\l";

            out << "shift: " << match->shift;
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

    std::ofstream* open_file(gress_t gress) {
        std::string outdir(BackendOptions().outputDir.c_str());
        outdir += "/graphs";

        int rc = mkdir(outdir.c_str(), 0755);
        if (rc != 0 && errno != EEXIST) {
            std::cerr << "Failed to create directory: " << outdir << std::endl;
            return nullptr;
        }

        static int fid = 0;
        std::string filepath = outdir + "/" + std::to_string(fid++) + "_" + filename
                                      + "_" + ::toString(gress) + ".dot";

        return new std::ofstream(filepath);
    }

    template <typename ParserGraphType>
    void dump_graph(const ParserGraphType& graph, gress_t gress) {
        out.str(std::string());

        out << "digraph parser {" << std::endl;
        out << "size=\"8,5\"" << std::endl;

        dump(graph, gress);

        out << "}" << std::endl;

        auto fs = open_file(gress);

        if (fs) {
            *fs << escape(out.str());
            fs->close();
        }
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
