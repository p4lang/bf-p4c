#ifndef BF_P4C_PARDE_EXTRACT_PARSER_H_
#define BF_P4C_PARDE_EXTRACT_PARSER_H_

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/exceptions.h"
#include "logging/pass_manager.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/parde/parde_visitor.h"

namespace IR {

namespace BFN {
class Deparser;
class Parser;
class Pipe;
}  // namespace BFN

class P4Control;
class P4Parser;

}  // namespace IR

namespace BFN {

/// Transform frontend parser and deparser into IR::BFN::Parser and IR::BFN::Deparser
class ExtractParser : public ParserInspector {
    Logging::FileLog *parserLog = nullptr;

 public:
    explicit ExtractParser(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
            IR::BFN::Pipe *rv, ParseTna *arch)
        : refMap(refMap), typeMap(typeMap), rv(rv), arch(arch) { setName("ExtractParser"); }
    void postorder(const IR::BFN::TnaParser* parser) override;
    void end_apply() override;

    profile_t init_apply(const IR::Node *root) override {
        if (BackendOptions().verbose > 0)
            parserLog = new Logging::FileLog(rv->canon_id(), "parser.log");
        return ParserInspector::init_apply(root);
    }

 private:
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;
    IR::BFN::Pipe *rv;
    ParseTna *arch;
};

/// Process IR::BFN::Parser and IR::BFN::Deparser to resolve header stack and add shim
/// for intrinsic metadata, must be applied to IR::BFN::Parser and IR::BFN::Deparser.
class ProcessParde : public Logging::PassManager {
 public:
    ProcessParde(const IR::BFN::Pipe *rv, bool useTna);
};

}  // namespace BFN

#endif /* BF_P4C_PARDE_EXTRACT_PARSER_H_ */
