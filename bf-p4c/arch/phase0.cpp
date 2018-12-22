#include "bf-p4c/arch/phase0.h"

#include <algorithm>
#include "bf-p4c/common/path_linearizer.h"
#include "bf-p4c/common/type_categories.h"
#include "bf-p4c/device.h"
#include "bf-p4c/lib/pad_alignment.h"
#include "bf-p4c/parde/field_packing.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/coreLibrary.h"
#include "frontends/p4/fromv1.0/v1model.h"
#include "frontends/p4/typeMap.h"
#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/indent.h"

namespace BFN {

namespace {

/// A helper type used to generate extracts in the phase 0 parser. Represents a
/// statement in the phase 0 table's action that writes an action parameter into a
/// metadata field.
struct Phase0WriteFromParam {
    /// The destination of the write (a metadata field).
    const IR::Member* dest;

    /// The source of the write (an action parameter name).
    cstring sourceParam;
};

/// A helper type used to generate extracts in the phase 0 parser. Represents a
/// statement in the phase 0 table's action that writes a constant into a
/// metadata field.
struct Phase0WriteFromConstant {
    /// The destination of the write (a metadata field).
    const IR::Member* dest;

    /// The source of the write (a numeric constant).
    const IR::Constant* value;
};

/// Metadata about the phase 0 table collected by FindPhase0Table. The
/// information is used by RewritePhase0IfPresent to generate a parser program,
/// an @phase 0 annotation, etc.
struct Phase0TableMetadata {
    /// The phase 0 table we found.
    const IR::P4Table* table = nullptr;

    /// The name of the phase 0 table's action as specified in the P4 program.
    cstring actionName;

    /// The table apply call that will be replaced with a phase 0 parser.
    const IR::MethodCallStatement* applyCallToReplace = nullptr;

    /// Parameters for the phase 0 table's action that need to get translated
    /// into a phase 0 data layout.
    const IR::ParameterList* actionParams = nullptr;

    /// Writes from action parameters that need to get translated into extracts
    /// from the input buffer in the phase 0 parser.
    std::vector<Phase0WriteFromParam> paramWrites;

    /// Writes from constants that need to get translated into constant extracts
    /// in the phase 0 parser.
    std::vector<Phase0WriteFromConstant> constantWrites;

    /// A P4 type for the phase 0 data, generated based on the parameters to the
    /// table's action.
    const IR::Type_Header* p4Type = nullptr;
};

/// Search the program for a table which may be implemented as a phase 0 table.
/// If one is found, `FindPhase0Table::phase0` is populated with the metadata
/// needed to generate the phase 0 program features.
struct FindPhase0Table : public Inspector {
    static constexpr int phase0TableSize = 288;

    FindPhase0Table(P4::ReferenceMap* refMap, P4::TypeMap* typeMap)
        : refMap(refMap), typeMap(typeMap) { }

    boost::optional<Phase0TableMetadata> phase0;

    bool preorder(const IR::BFN::TranslatedP4Control* control) override {
        // Phase 0 tables are only allowed in ingress.
        return control->thread == INGRESS;
    }

    bool preorder(const IR::P4Table* table) override {
        if (phase0) return false;

        phase0.emplace();
        phase0->table = table;
        LOG3("Checking if " << phase0->table->name << " is a valid phase 0 table");

        // Check if this table meets all of the phase 0 criteria.
        if (!hasCorrectSize(phase0->table)) {
            LOG3(" - Invalid size; expected " << phase0TableSize);
            phase0 = boost::none;
            return false;
        }
        LOG3(" - The size is correct");

        if (!hasNoSideEffects(phase0->table)) {
            LOG3(" - Invalid because it has side effects");
            phase0 = boost::none;
            return false;
        }
        LOG3(" - It has no side effects");

        if (!hasCorrectKey(phase0->table)) {
            LOG3(" - Invalid key; the phase 0 table should match against "
                 "`ingress_port`");
            phase0 = boost::none;
            return false;
        }
        LOG3(" - The key is correct");

        if (!hasValidAction(phase0->table)) {
            LOG3(" - Invalid action; the phase 0 table should contain one action "
                 "that only writes metadata fields and only reads constants or "
                 "action parameters");
            phase0 = boost::none;
            return false;
        }
        LOG3(" - The action is valid");

        if (!hasValidControlFlow(phase0->table)) {
            LOG3(" - Invalid control flow; the phase 0 table must be applied "
                 "first in ingress, and must be guarded with an `if` that "
                 "checks that `resubmit_flag` is zero");
            phase0 = boost::none;
            return false;
        }
        LOG3(" - The control flow is valid");

        if (!canPackDataIntoPhase0()) {
            LOG3(" - The action parameters are too large to pack into "
                   << Device::pardeSpec().bitPhase0Size() << " bits");
            phase0 = boost::none;
        }
        LOG3(" - The action parameters fit into the phase 0 data");

        LOG3(" - " << phase0->table->name << " will be used as the phase 0 table");
        return false;
    }

    bool preorder(const IR::Node*) override {
        // Continue only if we haven't found the phase 0 table yet.
        return !phase0;
    }

 private:
    bool hasCorrectSize(const IR::P4Table* table) const {
        // The phase 0 table's size must have a specific value.
        auto* sizeProperty = table->properties->getProperty("size");
        if (sizeProperty == nullptr) return false;
        if (!sizeProperty->value->is<IR::ExpressionValue>()) return false;
        auto* expression = sizeProperty->value->to<IR::ExpressionValue>()->expression;
        if (!expression->is<IR::Constant>()) return false;
        auto* size = expression->to<IR::Constant>();
        return size->fitsInt() && size->asInt() == phase0TableSize;
    }

    bool hasNoSideEffects(const IR::P4Table* table) const {
        // The phase 0 table cannot have any side effects or attached tables.
        // XXX(seth): This isn't a complete check; for example, we should forbid
        // stateful ALU.

        // Actions profiles aren't allowed.
        auto implProp = P4V1::V1Model::instance.tableAttributes
                                               .tableImplementation.name;
        if (table->properties->getProperty(implProp) != nullptr) return false;

        // Counters aren't allowed.
        auto counterProp = P4V1::V1Model::instance.tableAttributes
                                                  .counters.name;
        if (table->properties->getProperty(counterProp) != nullptr) return false;

        // Meters aren't allowed.
        auto meterProp = P4V1::V1Model::instance.tableAttributes
                                                .meters.name;
        if (table->properties->getProperty(meterProp) != nullptr) return false;

        return true;
    }

    bool hasCorrectKey(const IR::P4Table* table) const {
        // The phase 0 table must match against 'ingress_intrinsic_metadata.ingress_port'.
        auto* key = table->getKey();
        if (key == nullptr) return false;
        if (key->keyElements.size() != 1) return false;
        auto* keyElem = key->keyElements[0];
        if (!keyElem->expression->is<IR::Member>()) return false;
        auto* member = keyElem->expression->to<IR::Member>();
        auto* containingType = typeMap->getType(member->expr, true);
        if (!containingType->is<IR::Type_Declaration>()) return false;
        auto* containingTypeDecl = containingType->to<IR::Type_Declaration>();
        if (containingTypeDecl->name != "ingress_intrinsic_metadata_t") return false;
        if (member->member != "ingress_port") return false;

        // The match type must be 'exact'.
        auto* matchType = refMap->getDeclaration(keyElem->matchType->path, true)
                               ->to<IR::Declaration_ID>();
        if (matchType->name.name != P4::P4CoreLibrary::instance.exactMatch.name)
            return false;

        return true;
    }

    /// @return true if @expression is a parameter in the parameter list @params.
    bool isParam(const IR::Expression* expression,
                 const IR::ParameterList* params) const {
        if (!expression->is<IR::PathExpression>()) return false;
        auto* path = expression->to<IR::PathExpression>()->path;
        auto* decl = refMap->getDeclaration(path, true);
        if (!decl->is<IR::Parameter>()) return false;
        auto* param = decl->to<IR::Parameter>();
        for (auto* paramElem : params->parameters)
            if (paramElem == param) return true;
        return false;
    }

    bool hasValidAction(const IR::P4Table* table) {
        auto* actions = table->getActionList();
        if (actions == nullptr) return false;

        // Other than NoAction, the phase 0 table should have exactly one action.
        const IR::ActionListElement* actionElem = nullptr;
        for (auto* elem : actions->actionList) {
            if (elem->getName().name.startsWith("NoAction")) continue;
            if (actionElem != nullptr) return false;
            actionElem = elem;
        }
        if (actionElem == nullptr) return false;

        auto* decl = refMap->getDeclaration(actionElem->getPath(), true);
        BUG_CHECK(decl->is<IR::P4Action>(), "Action list element is not an action?");
        auto* action = decl->to<IR::P4Action>();

        // Save the action name for assembly output.
        phase0->actionName = action->externalName();

        // The action should have only action data parameters.
        for (auto* param : *action->parameters)
            if (param->direction != IR::Direction::None) return false;

        // Save the action parameters; we'll use them to generate the header
        // type that defines the format of the phase 0 data.
        phase0->actionParams = action->parameters;

        for (auto* statement : action->body->components) {
            // The action should contain only assignments.
            if (!statement->is<IR::AssignmentStatement>()) return false;
            auto* assignment = statement->to<IR::AssignmentStatement>();
            auto* dest = assignment->left;
            auto* source = assignment->right;

            // The action should write to metadata fields only.
            // XXX(seth): Ideally we'd also verify that it only writes to fields
            // that the parser doesn't already write to.
            PathLinearizer path;
            dest->apply(path);
            if (!path.linearPath) {
                LOG5("   - Assigning to an expression which is too complex: " << dest);
                return false;
            }

            if (!isMetadataReference(*path.linearPath, typeMap)) {
                LOG5("   - Assigning to an expression of non-metadata type: " << dest);
                return false;
            }

            // Remove any casts around the source of the assignment. (These are
            // often introduced as a side effect of translation.)
            while (auto* cast = source->to<IR::Cast>()) {
                source = cast->expr;
            }

            // The action should only read from constants or its parameters.
            if (source->is<IR::Constant>()) {
                phase0->constantWrites.emplace_back(Phase0WriteFromConstant {
                    dest->to<IR::Member>(),
                    source->to<IR::Constant>()
                });
                continue;
            }

            if (!isParam(source, action->parameters)) {
                LOG5("   - Assigning from a value which is not a constant or "
                     "an action parameter: " << source);
                return false;
            }

            phase0->paramWrites.emplace_back(Phase0WriteFromParam {
                dest->to<IR::Member>(),
                source->to<IR::PathExpression>()->path->name.name
            });
        }

        return true;
    }

    bool hasValidControlFlow(const IR::P4Table* table) {
        // The phase 0 table should be applied in the control's first statement.
        auto* control = findContext<IR::P4Control>();
        if (!control) return false;
        if (control->body->components.size() == 0) return false;
        auto& statements = control->body->components;

        // That statement should be an `if` statement.
        if (!statements[0]->is<IR::IfStatement>()) return false;
        auto* ifStatement = statements[0]->to<IR::IfStatement>();
        if (!ifStatement->condition->is<IR::Equ>()) return false;
        auto* equ = ifStatement->condition->to<IR::Equ>();

        // The `if` should check that `ingress_intrinsic_metadata.resubmit_flag` is 0.
        auto* member = equ->left->to<IR::Member>()
                     ? equ->left->to<IR::Member>()
                     : equ->right->to<IR::Member>();
        auto* constant = equ->left->to<IR::Constant>()
                       ? equ->left->to<IR::Constant>()
                       : equ->right->to<IR::Constant>();
        if (member == nullptr || constant == nullptr) return false;
        auto* containingType = typeMap->getType(member->expr, true);
        if (!containingType->is<IR::Type_Declaration>()) return false;
        auto* containingTypeDecl = containingType->to<IR::Type_Declaration>();
        if (containingTypeDecl->name != "ingress_intrinsic_metadata_t") return false;
        if (member->member != "resubmit_flag") return false;
        if (!constant->fitsInt() || constant->asInt() != 0) return false;

        // The body of the `if` should consist only of the table apply call.
        if (!ifStatement->ifTrue->is<IR::MethodCallStatement>()) return false;
        phase0->applyCallToReplace = ifStatement->ifTrue->to<IR::MethodCallStatement>();
        auto* mi = P4::MethodInstance::resolve(phase0->applyCallToReplace,
                                               refMap, typeMap);
        if (!mi->isApply() || !mi->to<P4::ApplyMethod>()->isTableApply()) return false;
        if (mi->object != table) return false;

        return true;
    }

    bool canPackDataIntoPhase0() {
        // Generate the phase 0 data layout.
        FieldPacking packing;
        for (auto* param : *phase0->actionParams) {
            BUG_CHECK(param->type, "No type for phase 0 parameter %1%?", param);

            // Align the field so that its LSB lines up with a byte boundary,
            // which (usually) reproduces the behavior of the PHV allocator.
            // XXX(seth): Once `@layout("flexible")` is properly supported in
            // the backend, we won't need this (or any padding), so we should
            // remove it at that point.
            const int fieldSize = param->type->width_bits();
            const int alignment = getAlignment(fieldSize);
            packing.padToAlignment(8, alignment);
            packing.appendField(new IR::PathExpression(param->name),
                                param->name, fieldSize);
            packing.padToAlignment(8);
        }

        // Pad out the layout to fill the available phase 0 space.
        packing.padToAlignment(Device::pardeSpec().bitPhase0Size());

        // Make sure we didn't overflow.
        if (packing.totalWidth != Device::pardeSpec().bitPhase0Size())
            return false;

        // Use the layout to construct a type for phase 0 data.
        IR::IndexedVector<IR::StructField> fields;
        unsigned padFieldId = 0;
        for (auto& packedField : packing) {
            if (packedField.isPadding()) {
                cstring padFieldName = "__pad_";
                padFieldName += cstring::to_cstring(padFieldId++);
                auto* padFieldType = IR::Type::Bits::get(packedField.width);
                fields.push_back(new IR::StructField(padFieldName, new IR::Annotations({
                        new IR::Annotation(IR::ID("hidden"), { })
                    }), padFieldType));
                continue;
            }

            auto* fieldType = IR::Type::Bits::get(packedField.width);
            fields.push_back(new IR::StructField(packedField.source, fieldType));
        }

        // Generate the P4 type. We add an `@layout("flexible")` annotation to
        // allow PHV allocation to choose an optimal layout for the header.
        auto* layoutKind = new IR::StringLiteral(IR::ID("flexible"));
        phase0->p4Type = new IR::Type_Header("__phase0_header", new IR::Annotations({
                new IR::Annotation(IR::ID("layout"), { layoutKind })
            }), fields);

        return true;
    }

    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;
};

/// Generate the phase 0 program features based upon the Phase0TableMetadata
/// produced by FindPhase0Table. If no Phase0TableMetadata is provided (i.e.,
/// no phase 0 table was found) then no changes are made.
struct RewritePhase0IfPresent : public Transform {
    explicit RewritePhase0IfPresent(const boost::optional<Phase0TableMetadata>& phase0)
        : phase0(phase0) { }

    profile_t init_apply(const IR::Node* root) override {
        // Make sure we're operating on a P4Program; otherwise, we won't skip
        // the pass even if no phase 0 table was found, and we'll run into bugs.
        BUG_CHECK(root->is<IR::P4Program>(),
                  "RewritePhase0IfPresent expects a P4Program");
        return Transform::init_apply(root);
    }

    const IR::P4Program* preorder(IR::P4Program* program) override {
        // Skip this pass entirely if we didn't find a phase 0 table.
        if (!phase0) {
            LOG4("No phase 0 table found; skipping phase 0 translation");
            prune();
            return program;
        }

        // Inject an explicit declaration for the phase 0 data type into the
        // program.
        LOG4("Injecting declaration for phase 0 type: " << phase0->p4Type);
        IR::IndexedVector<IR::Node> declarations;
        declarations.push_back(phase0->p4Type);
        program->objects.insert(program->objects.begin(),
                                declarations.begin(), declarations.end());

        return program;
    }

    IR::Type_StructLike* preorder(IR::Type_StructLike* type) override {
        prune();
        if (type->name != "compiler_generated_metadata_t") return type;

        // Inject a new field to hold the phase 0 data.
        LOG4("Injecting field for phase 0 data into: " << type);
        type->fields.push_back(new IR::StructField("__phase0_data",
                                                   phase0->p4Type));
        return type;
    }

    const IR::StatOrDecl* preorder(IR::MethodCallStatement* methodCall) override {
        prune();

        // If this is the apply() call that invoked the phase 0 table, remove
        // it. Note that we don't remove the table itself, since it may be
        // invoked in more than one place. If this was the only usage, it'll be
        // implicitly removed anyway when we do dead code elimination later.
        if (getOriginal<IR::MethodCallStatement>() == phase0->applyCallToReplace) {
            LOG4("Removing phase 0 table apply() call: " << methodCall);
            BUG_CHECK(getParent<IR::IfStatement>() != nullptr,
                      "Expected apply call for phase 0 table to be the body of "
                      "an `if` statement: %1%", methodCall);
            return new IR::BlockStatement;
        }

        return methodCall;
    }

    // Generate phase0 node in parser based on info extracted for phase0
    const IR::BFN::TranslatedP4Parser*
    preorder(IR::BFN::TranslatedP4Parser* parser) override {
        if (parser->thread != INGRESS) {
            prune();
            return parser;
        }
        auto size = Device::numMaxChannels();
        auto tableName = phase0->table->controlPlaneName();
        auto actionName = phase0->actionName;
        auto keyName = "";
        auto *fieldVec = &phase0->p4Type->fields;
        auto handle = 0x20 << 24;
        parser->phase0 =
            new IR::BFN::Phase0(fieldVec, size, handle, tableName, actionName, keyName);
        return parser;
    }

    const IR::ParserState* preorder(IR::ParserState* state) override {
        if (state->name != "__phase0") return state;
        prune();

        auto* tnaContext = findContext<IR::BFN::TranslatedP4Parser>();
        BUG_CHECK(tnaContext, "Phase 0 state not within translated parser?");
        BUG_CHECK(tnaContext->thread == INGRESS, "Phase 0 state not in ingress?");

        // Clear the existing statements in the state, which are just
        // placeholders.
        state->components.clear();

        // Add "pkt.extract(compiler_generated_meta.__phase0_data)"
        auto cgMeta = tnaContext->tnaParams.at("compiler_generated_meta");
        auto packetInParam = tnaContext->tnaParams.at("pkt");
        auto* method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("extract"));
        auto* member = new IR::Member(new IR::PathExpression(cgMeta),
                                      IR::ID("__phase0_data"));
        auto* args = new IR::Vector<IR::Argument>({ new IR::Argument(member) });
        auto* callExpr = new IR::MethodCallExpression(method, args);
        auto* extract = new IR::MethodCallStatement(callExpr);
        LOG4("Generated extract for phase 0 data: " << extract);
        state->components.push_back(extract);

        // Generate assignments that copy the extracted phase 0 fields to their
        // final locations. The original extracts will get optimized out.
        for (auto& paramWrite : phase0->paramWrites) {
            auto* member = new IR::Member(new IR::PathExpression(cgMeta),
                                          IR::ID("__phase0_data"));
            auto* fieldMember =
                new IR::Member(member, IR::ID(paramWrite.sourceParam));
            auto* assignment = new IR::AssignmentStatement(paramWrite.dest, fieldMember);
            LOG4("Generated assignment for phase 0 write from parameter: "
                    << assignment);
            state->components.push_back(assignment);
        }

        // Generate assignments for the constant writes.
        for (auto& constant : phase0->constantWrites) {
            auto* assignment = new IR::AssignmentStatement(constant.dest,
                                                           constant.value);
            LOG4("Generated assignment for phase 0 write from constant: "
                    << assignment);
            state->components.push_back(assignment);
        }

        return state;
    }

 private:
    const boost::optional<Phase0TableMetadata>& phase0;
};

}  // namespace

TranslatePhase0::TranslatePhase0(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) {
    auto* findPhase0Table = new FindPhase0Table(refMap, typeMap);
    addPasses({
        findPhase0Table,
        new RewritePhase0IfPresent(findPhase0Table->phase0)
    });
}

}  // namespace BFN
