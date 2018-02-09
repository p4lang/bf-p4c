#ifndef EXTENSIONS_BF_P4C_COMMON_UTILS_H_
#define EXTENSIONS_BF_P4C_COMMON_UTILS_H_

#include <boost/algorithm/string.hpp>
#include <fstream>

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


struct DumpParser : public Inspector {
    explicit DumpParser(cstring filename) {
        out = &std::cout;
        if (filename)
            out = new std::ofstream(filename);
    }

    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = Inspector::init_apply(root);
        *out << "digraph parser {" << std::endl;
        *out << "size=\"8,5\"" << std::endl;
        return rv;
    }

    static cstring escape_name(cstring name) {
        std::string es(name.c_str());
        boost::replace_all(es, "::", "_");
        boost::replace_all(es, "$", "");
        boost::replace_all(es, ".", "_");
        return es.c_str();
    }

    bool preorder(const IR::BFN::Parser* parser) override {
        cstring gress = parser->gress ? "cluster_egress" : "cluster_ingress";
        *out << "subgraph " << gress << " {" << std::endl;
        return true;
    }

    void postorder(const IR::BFN::Parser* parser) override {
        cstring gress = parser->gress ? "cluster_egress" : "cluster_ingress";
        *out << "} #" << gress << std::endl;
    }

    bool preorder(const IR::BFN::ParserState* state) override {
        auto *pred = findContext<IR::BFN::ParserState>();
        if (pred)
            *out << escape_name(pred->name) << " -> " << escape_name(state->name) << std::endl;
        return true;
    }

    void end_apply() override {
        *out << "}" << std::endl;;
    }

    std::ostream* out = nullptr;
};

#endif /* EXTENSIONS_BF_P4C_COMMON_UTILS_H_ */
