#include "bf-p4c/arch/intrinsic_metadata.h"
#include "bf-p4c/arch/t2na.h"

namespace BFN {

// visit parser state in control flow order, count up to the first 8 bytes, skip next 8 bytes.
struct RewriteIntrinsicMeta : public ControlFlowVisitor, Inspector {
    RewriteIntrinsicMeta() { setName("RewriteInstrinsicMeta"); }

    RewriteIntrinsicMeta *clone() const override { return new RewriteIntrinsicMeta(*this); }

    bool preorder(const IR::BFN::TranslatedP4Parser *parser) override {
        gress_t thread = parser->thread;
        if (thread != INGRESS) return false;
        return true;
    }

    bool preorder(const IR::ParserState* state) override {
        LOG1("state " << state);
        return false;
    }

    // start from the beginning of the parser.
    // control flow visit parser.
    // count the number of bytes extracted so far.
    // if extracted == 64, add advance(64)
    // if extracted > 64, error
    // if extracted < 64, continue
};

    PortTNAToJBay::PortTNAToJBay(P4::ReferenceMap* /* refMap */,
                                 P4::TypeMap* /* typeMap */,
                                 BFN_Options& /* options */) {
    addPasses({
        new RewriteIntrinsicMeta()
    });
}

}  // namespace BFN
