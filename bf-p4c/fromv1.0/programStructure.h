#ifndef EXTENSIONS_BF_P4C_FROMV1_0_PROGRAMSTRUCTURE_H_
#define EXTENSIONS_BF_P4C_FROMV1_0_PROGRAMSTRUCTURE_H_

#include "frontends/p4/fromv1.0/converters.h"
#include "frontends/p4/fromv1.0/programStructure.h"

namespace P4V1 {

class TNA_ProgramStructure : public ProgramStructure {
    const IR::Expression* convertHashAlgorithm(Util::SourceInfo srcInfo,
        IR::ID algorithm) override;

    const IR::P4Table* convertTable(const IR::V1Table* table, cstring newName,
        IR::IndexedVector<IR::Declaration> &stateful, std::map<cstring, cstring> &) override;
 public:
    static ProgramStructure *create() { return new TNA_ProgramStructure(); }
};

IR::BlockStatement *generate_hash_block_statement(
        P4V1::ProgramStructure * structure, const IR::Primitive *prim,
        const cstring temp, ExpressionConverter &conv, unsigned num_ops);
}  // namespace P4V1

#endif /* EXTENSIONS_BF_P4C_FROMV1_0_PROGRAMSTRUCTURE_H_ */
