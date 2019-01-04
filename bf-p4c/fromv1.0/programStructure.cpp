#include "programStructure.h"
#include "lib/error.h"

const IR::Expression *
P4V1::TNA_ProgramStructure::convertHashAlgorithm(Util::SourceInfo srcInfo, IR::ID algorithm) {
    include("tofino/p4_14_prim.p4", "-D_TRANSLATE_TO_V1MODEL");
    return IR::MAU::HashFunction::convertHashAlgorithmBFN(srcInfo, algorithm, nullptr);
}

IR::BlockStatement *
P4V1::generate_hash_block_statement(P4V1::ProgramStructure *structure,
        const IR::Primitive *prim, const cstring temp, ExpressionConverter &conv, int num_ops) {
        BUG_CHECK(prim->operands.size() == num_ops, "Wrong number of operands to %s", prim->name);
        auto pe = prim->operands.at(num_ops - 1)->to<IR::PathExpression>();
        auto flc = pe ? structure->field_list_calculations.get(pe->path->name) : nullptr;
        if (!flc) {
            error("%s: Expected a field_list_calculation", prim->operands.at(1));
            return nullptr; }
        IR::BlockStatement *block = new IR::BlockStatement;
        auto ttype = IR::Type_Bits::get(flc->output_width);
        block->push_back(new IR::Declaration_Variable(temp, ttype));
        auto block_args = new IR::Vector<IR::Argument>();
        block_args->push_back(new IR::Argument(new IR::PathExpression(new IR::Path(temp))));
        block_args->push_back(new IR::Argument(structure->convertHashAlgorithms(flc->algorithm)));
        block_args->push_back(new IR::Argument(new IR::Constant(ttype, 0)));
        block_args->push_back(new IR::Argument(conv.convert(flc->input_fields)));
        block_args->push_back(new IR::Argument(
            new IR::Constant(IR::Type_Bits::get(flc->output_width + 1), 1 << flc->output_width)));
        block->push_back(new IR::MethodCallStatement(new IR::MethodCallExpression(
                new IR::PathExpression(structure->v1model.hash.Id()), block_args)));
        return block;
}
