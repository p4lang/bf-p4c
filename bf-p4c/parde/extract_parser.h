#ifndef BF_P4C_PARDE_EXTRACT_PARSER_H_
#define BF_P4C_PARDE_EXTRACT_PARSER_H_

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/exceptions.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"
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
 public:
    explicit ExtractParser(P4::ReferenceMap* refMap, P4::TypeMap* typeMap, IR::BFN::Pipe *rv)
        : refMap(refMap), typeMap(typeMap), rv(rv) { setName("ExtractParser"); }
    void postorder(const IR::BFN::TranslatedP4Parser* parser) override;
    void end_apply() override;

 private:
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;
    IR::BFN::Pipe *rv;
};

/// Process IR::BFN::Parser and IR::BFN::Deparser to resolve header stack and add shim
/// for intrinsic metadata, must be applied to IR::BFN::Parser and IR::BFN::Deparser.
class ProcessParde : public PassManager {
 public:
    ProcessParde(const IR::BFN::Pipe *rv, bool useTna);
};

}  // namespace BFN

#endif /* BF_P4C_PARDE_EXTRACT_PARSER_H_ */
