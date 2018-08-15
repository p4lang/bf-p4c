#include "programStructure.h"
#include "lib/error.h"

const IR::Expression *
P4V1::TNA_ProgramStructure::convertHashAlgorithm(Util::SourceInfo srcInfo, IR::ID algorithm) {
    include("tofino/p4_14_prim.p4", "-D_TRANSLATE_TO_V1MODEL");
    return IR::MAU::hash_function::convertHashAlgorithmBFN(srcInfo, algorithm, nullptr);
}
