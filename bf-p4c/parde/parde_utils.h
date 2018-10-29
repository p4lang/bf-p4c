#ifndef EXTENSIONS_BF_P4C_PARDE_PARDE_UTILS_H_
#define EXTENSIONS_BF_P4C_PARDE_PARDE_UTILS_H_

#include <boost/algorithm/string.hpp>
#include <fstream>

#include "bf-p4c/parde/parser_graph.h"

struct DumpParser : public Visitor {
    cstring filename;
    std::stringstream out;
    bool detail = true;

    explicit DumpParser(cstring filename, bool detail = true)
        : filename(filename), detail(detail) {}

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

    static
    std::string state_label(const IR::BFN::ParserState* state) {
        std::stringstream ss;
        ss << "State" << (void*)state;  // NOLINT
        return ss.str();
    }

    void dump(const IR::BFN::Transition* transition) {
        out << "[ label=\"" << transition << "\" ]";
    }

    void dump(const IR::BFN::ParserState* state) {
        out << state_label(state) << " [shape=record";
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

    void dump(const ParserGraph& graph, gress_t gress) {
        for (auto s : graph.states())
            dump(s);

        for (auto succ : graph.successors()) {
            for (auto dst : succ.second) {
                out << state_label(succ.first) << " -> " << state_label(dst);

                if (detail)
                    dump(graph.transition(succ.first, dst));

                out << std::endl;
            }
        }

        for (auto &kv : graph.to_pipe()) {
            out << state_label(kv.first) << " -> " << ::toString(gress) << "_pipe";

            if (detail)
                dump(graph.to_pipe(kv.first));

            out << std::endl;
        }
    }

    const IR::Node *apply_visitor(const IR::Node *n, const char*) override { return n; }

    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = Visitor::init_apply(root);

        CollectParserInfo cg;
        root->apply(cg);

        for (auto g : cg.graphs()) {
            out.str(std::string());

            out << "digraph parser {" << std::endl;
            out << "size=\"8,5\"" << std::endl;

            dump(*(g.second), g.first->gress);

            out << "}" << std::endl;

            std::ofstream fs(filename + "_" + ::toString(g.first->gress) + ".dot");

            fs << escape(out.str());

            fs.close();
        }

        return rv;
    }
};

#endif /* EXTENSIONS_BF_P4C_PARDE_PARDE_UTILS_H_ */
