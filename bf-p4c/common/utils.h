#ifndef EXTENSIONS_BF_P4C_COMMON_UTILS_H_
#define EXTENSIONS_BF_P4C_COMMON_UTILS_H_

#include <boost/algorithm/string.hpp>
#include <fstream>

#include "bf-p4c/common/parser_graph.h"

struct DumpPipe : public Inspector {
    const char *heading;
    DumpPipe() : heading(nullptr) {}
    explicit DumpPipe(const char *h) : heading(h) {}
    bool preorder(const IR::Node *pipe) override {
        if (Log::verbose() || LOGGING(1)) {
            if (heading)
                std::cout << "-------------------------------------------------" << std::endl
                          << heading << std::endl
                          << "-------------------------------------------------" << std::endl;
            if (LOGGING(2))
                dump(pipe);
            else
                std::cout << *pipe << std::endl; }
        return false; }
};

struct DumpParser : public Visitor {
    cstring filename;

    explicit DumpParser(cstring filename) : filename(filename) {}

    static cstring escape_name(cstring name) {
        std::string es(name.c_str());
        boost::replace_all(es, "ingress::", "");
        boost::replace_all(es, "egress::", "");
        boost::replace_all(es, "$", "");
        boost::replace_all(es, ".", "_");
        return es.c_str();
    }

    static void write_cluster(std::ostream &out, const ParserGraph& graph, gress_t gress) {
        for (auto succ : graph.successors())
            for (auto dst : succ.second)
                out << escape_name((succ.first)->name)
                    << " -> " << escape_name(dst->name) << std::endl;

        for (auto src : graph.to_pipe())
            out << escape_name(src->name) << " -> " << ::toString(gress) << "_pipe" << std::endl;
    }

    const IR::Node *apply_visitor(const IR::Node *n, const char*) override { return n; }

    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = Visitor::init_apply(root);

        CollectParserInfo cg;
        root->apply(cg);

        for (auto g : cg.graphs()) {
            std::ofstream out(filename + "_" + ::toString(g.first->gress) + ".dot");

            out << "digraph parser {" << std::endl;
            out << "size=\"8,5\"" << std::endl;

            write_cluster(out, *(g.second), g.first->gress);

            out << "}" << std::endl;
        }

        return rv;
    }
};

#endif /* EXTENSIONS_BF_P4C_COMMON_UTILS_H_ */
