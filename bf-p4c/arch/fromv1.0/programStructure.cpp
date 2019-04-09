#include "programStructure.h"
#include "lib/error.h"

const IR::Expression *
P4V1::TNA_ProgramStructure::convertHashAlgorithm(Util::SourceInfo srcInfo, IR::ID algorithm) {
    include("tofino/p4_14_prim.p4", "-D_TRANSLATE_TO_V1MODEL");
    return IR::MAU::HashFunction::convertHashAlgorithmBFN(srcInfo, algorithm, nullptr);
}

IR::BlockStatement *
P4V1::generate_hash_block_statement(P4V1::ProgramStructure *structure, const IR::Primitive *prim,
        const cstring temp, ExpressionConverter &conv, unsigned num_ops) {
    BUG_CHECK(prim->operands.size() == num_ops, "Wrong number of operands to %s", prim->name);
    auto pe = prim->operands.at(num_ops - 1)->to<IR::PathExpression>();
    auto flc = pe ? structure->field_list_calculations.get(pe->path->name) : nullptr;
    if (!flc) {
        error("%s: Expected a field_list_calculation", prim->operands.at(1));
        return nullptr; }
    IR::BlockStatement *block = new IR::BlockStatement;
    auto ttype = IR::Type_Bits::get(flc->output_width);
    block->push_back(new IR::Declaration_Variable(temp, ttype));

    auto fl = structure->getFieldLists(flc);
    if (fl == nullptr)
        return nullptr;
    const IR::ListExpression *listExp = conv.convert(fl)->to<IR::ListExpression>();
    auto list = new IR::HashListExpression(flc->srcInfo,
            listExp->components, flc->name, flc->output_width);
    list->fieldListNames = flc->input;
    if (flc->algorithm->names.size() > 0)
        list->algorithms = flc->algorithm;

    auto block_args = new IR::Vector<IR::Argument>();
    block_args->push_back(new IR::Argument(new IR::PathExpression(new IR::Path(temp))));
    block_args->push_back(new IR::Argument(structure->convertHashAlgorithms(flc->algorithm)));
    block_args->push_back(new IR::Argument(new IR::Constant(ttype, 0)));
    block_args->push_back(new IR::Argument(list));
    block_args->push_back(new IR::Argument(
        new IR::Constant(IR::Type_Bits::get(flc->output_width + 1), 1 << flc->output_width)));
    block->push_back(new IR::MethodCallStatement(new IR::MethodCallExpression(
            new IR::PathExpression(structure->v1model.hash.Id()), block_args)));
    return block;
}

// This convertTable function calls the parent frontend convertTable function
// and appends additional info required for the backend. This is currently
// restricted to action selectors and pulls out information on hash calculation
// which is used by PD Generation.
// For future use, this can be expanded to include other info used by backend
// which is not extracted from the frontend function call.
const IR::P4Table*
P4V1::TNA_ProgramStructure::convertTable(const IR::V1Table* table, cstring newName,
                               IR::IndexedVector<IR::Declaration> &stateful,
                               std::map<cstring, cstring> &mapNames) {
    // Generate p4Table from frontend call
    auto p4Table = ProgramStructure::convertTable(table, newName, stateful, mapNames);

    // Check for action selector and generate a new IR::P4Table with additional
    // annotations for hash info required for PD Generation
    cstring profile = table->action_profile.name;
    auto *action_profile = action_profiles.get(profile);
    auto *action_selector = action_profile ?
        action_selectors.get(action_profile->selector.name) : nullptr;

    if (action_selector) {
        auto flc = field_list_calculations.get(action_selector->key.name);
        if (flc) {
            auto annos = p4Table->getAnnotations();
            annos = annos->addAnnotation("action_selector_hash_field_calc_name",
                                                new IR::StringLiteral(flc->name));
            annos = annos->addAnnotation("action_selector_hash_field_list_name",
                                                new IR::StringLiteral(flc->input->names[0]));
            for (auto a : flc->algorithm->names) {
                annos = annos->addAnnotation("algorithm", new IR::StringLiteral(a));
            }
            annos = annos->addAnnotation("action_selector_hash_field_calc_output_width",
                                                new IR::Constant(flc->output_width));
            auto newP4Table = new IR::P4Table(p4Table->srcInfo, newName,
                                    annos, p4Table->properties);
            LOG4("Adding dynamic hash annotations: " << annos << " to table " << table->name);
            return newP4Table;
        }
    }
    return p4Table;
}

const IR::Declaration_Instance*
P4V1::TNA_ProgramStructure::convertActionProfile(const IR::ActionProfile* action_profile,
        cstring newName) {
    // Generate decl from frontend call
    auto decl = ProgramStructure::convertActionProfile(action_profile, newName);

    // Add annotations from action profile to the declaration
    auto newDecl = new IR::Declaration_Instance(decl->name,
                        action_profile->annotations, decl->type, decl->arguments, nullptr);
    return newDecl;
}
