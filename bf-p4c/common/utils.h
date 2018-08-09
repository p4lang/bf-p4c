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
    explicit DumpParser(cstring filename) {
        out = &std::cout;
        if (filename)
            out = new std::ofstream(filename);
    }

    static cstring escape_name(cstring name) {
        std::string es(name.c_str());
        boost::replace_all(es, "::", "_");
        boost::replace_all(es, "$", "");
        boost::replace_all(es, ".", "_");
        return es.c_str();
    }

    static void write_cluster(std::ostream &out, const ParserGraph& graph/*, cstring gress*/) {
        // out << "subgraph cluster_" << gress << "{" << std::endl;
        for (auto succ : graph.successors())
            for (auto dst : succ.second)
                out << escape_name((succ.first)->name)
                    << " -> " << escape_name(dst->name) << std::endl;

        static cstring gress = "";  // TODO(zma) get this from graph
        gress += "_";
        for (auto src : graph.to_pipe())
            out << escape_name(src->name) << " -> " << gress << "_pipe" << std::endl;

        // out << "}" << std::endl;
    }

    const IR::Node *apply_visitor(const IR::Node *n, const char*) override { return n; }

    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = Visitor::init_apply(root);

        CollectParserInfo cg;
        root->apply(cg);

        *out << "digraph parser {" << std::endl;
        *out << "size=\"8,5\"" << std::endl;

        for (auto g : cg.graphs())
            write_cluster(*out, *(g.second));

        *out << "}" << std::endl;

        return rv;
    }

    std::ostream* out = nullptr;
};

#endif /* EXTENSIONS_BF_P4C_COMMON_UTILS_H_ */
