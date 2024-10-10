#include "bf-p4c/arch/fromv1.0/checksum.h"

namespace BFN {
namespace V1 {

TranslateParserChecksums::TranslateParserChecksums(ProgramStructure *structure,
                                                   P4::ReferenceMap *refMap,
                                                   P4::TypeMap *typeMap)
        : parserGraphs(refMap, cstring()) {
    auto collectParserChecksums = new BFN::V1::CollectParserChecksums(refMap, typeMap);
    auto insertParserChecksums = new BFN::V1::InsertParserChecksums(this,
                                                  collectParserChecksums,
                                                  &parserGraphs,
                                                  structure);
    addPasses({&parserGraphs,
               collectParserChecksums,
               insertParserChecksums
              });
}

}  // namespace V1
}  // namespace BFN
