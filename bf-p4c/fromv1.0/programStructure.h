#ifndef EXTENSIONS_BF_P4C_FROMV1_0_PROGRAMSTRUCTURE_H_
#define EXTENSIONS_BF_P4C_FROMV1_0_PROGRAMSTRUCTURE_H_

#include "frontends/p4/fromv1.0/converters.h"
#include "frontends/p4/fromv1.0/programStructure.h"

namespace P4V1 {

class TNA_ProgramStructure : public ProgramStructure {
    const IR::Expression* convertHashAlgorithm(Util::SourceInfo srcInfo,
        IR::ID algorithm) override;

 public:
    static ProgramStructure *create() { return new TNA_ProgramStructure(); }
};

}  // namespace P4V1

#endif /* EXTENSIONS_BF_P4C_FROMV1_0_PROGRAMSTRUCTURE_H_ */
