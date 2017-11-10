#include "bf-p4c/parde/phase0.h"

#include <algorithm>
#include "bf-p4c/device.h"
#include "bf-p4c/parde/field_packing.h"
#include "frontends/p4/coreLibrary.h"
#include "frontends/p4/fromv1.0/v1model.h"
#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/indent.h"

std::ostream& operator<<(std::ostream& out, const BFN::Phase0Info* info) {
    if (info == nullptr) return out;
    CHECK_NULL(info->table);
    CHECK_NULL(info->packing);

    // Boilerplate. This is mostly just for the convenience of the assembler and
    // the driver; the only thing that varies is the table name.
    // XXX(seth): We can probably pare this down quite a bit, but for now this
    // reproduces what Glass produces.
    auto tableName = info->table->controlPlaneName();
    indent_t indent(1);
    out <<   indent << "phase0_match " << tableName << ":" << std::endl;
    out << ++indent << "p4:" << std::endl;
    out << ++indent << "name: " << tableName << std::endl;
    out <<   indent << "size: 288" << std::endl;
    out <<   indent << "preferred_match_type: exact" << std::endl;
    out <<   indent << "match_type: exact" << std::endl;
    out << --indent << "size: 288" << std::endl;

    // Write out the p4 parameter, which (for phase0) is always
    // 'ig_intr_md.ingress_port'
    out <<   indent << "p4_param_order:" << std::endl;
    out << ++indent << "ig_intr_md.ingress_port: ";
    out << "{ type: exact, size: 9 }" << std::endl;

    // Write out the field packing format. We have to convert into the LSB-first
    // representation that the assembler uses.
    const nw_bitrange phase0Range =
      StartLen(0, Device::pardeSpec().bitPhase0Size());
    BUG_CHECK(info->packing->totalWidth == phase0Range.size(),
              "Expected phase 0 field packing to allocate exactly %1% bits",
              phase0Range.size());
    bool wroteAtLeastOneField = false;
    int posBits = 0;
    out << --indent << "format: {";
    for (auto& field : *info->packing) {
        BUG_CHECK(field.width > 0, "Empty phase 0 field?");
        const nw_bitrange fieldRange(StartLen(posBits, field.width));
        BUG_CHECK(phase0Range.contains(fieldRange),
                  "Phase 0 allocation %1% overflows the phase 0 region %2% for "
                  "field %3%", fieldRange, phase0Range,
                  field.isPadding() ? "(padding)" : field.source);

        posBits += field.width;
        if (field.isPadding()) continue;
        if (wroteAtLeastOneField) out << ", ";
        wroteAtLeastOneField = true;

        const le_bitrange leFieldRange =
          fieldRange.toOrder<Endian::Little>(phase0Range.size());
        out << field.source << ": " << leFieldRange.lo;
        if (leFieldRange.size() > 1) out << ".." << leFieldRange.hi;
    }
    out << "}" << std::endl;

    // Write out the constant value. This value is used by the driver to
    // initialize the phase 0 data before the bits assigned to fields are given
    // their user-provided values. Having this available gives us a little more
    // flexibility when packing phase 0 fields.
    // XXX(seth): The above isn't actually implemented, but it's planned. Right
    // now, the driver acts as if this is always set to zero.
    out << indent << "constant_value: 0" << std::endl;

    // Write out the actions block with the param order
    // XXX(amresh): This is a fake action block output in assembly to allow
    // generating context json as expected by driver. No instructions are
    // generated as,
    // 1. phase0 does not do any actual ALU operations
    // 2. This info is not needed in the context json (for now).
    // Glass does generate primitives (for model logging - previously
    // p4_name_lookup) which requires setting ingress metadata fields as ALU ops
    // but it is unclear if model uses this info.
    out << indent << "actions:" << std::endl;
    out << ++indent << info->actionName << ":" << std::endl;
    out <<   indent << "- p4_param_order: { ";
    wroteAtLeastOneField = false;
    for (auto& field : *info->packing) {
        if (field.isPadding()) continue;
        if (wroteAtLeastOneField) out << ", ";
        out << field.source << ": " << field.width;
        wroteAtLeastOneField = true;
    }
    out << " } " << std::endl;
    return out;
}

namespace BFN {

typedef std::map<const IR::Member*, cstring> Phase0Extracts;
typedef std::map<const IR::Member*, const IR::Constant*> Phase0Constants;

class FindPhase0Table : public Inspector {
  bool hasCorrectSize(const IR::P4Table* table) const {
      // The phase 0 table's size must be 288.
      auto sizeProperty = table->properties->getProperty("size");
      if (sizeProperty == nullptr) return false;
      if (!sizeProperty->value->is<IR::ExpressionValue>()) return false;
      auto expression = sizeProperty->value->to<IR::ExpressionValue>()->expression;
      if (!expression->is<IR::Constant>()) return false;
      auto size = expression->to<IR::Constant>();
      return size->fitsInt() && size->asInt() == 288;
  }

  bool hasNoSideEffects(const IR::P4Table* table) const {
      // The phase 0 table cannot have any side effects or attached tables.
      // XXX(seth): This isn't a complete check; for example, we should forbid
      // stateful ALU. In general this would be easier if we waited until this
      // table was converted into an IR::Mau::Table and just checked the list of
      // attached tables. I've tried to avoid that because in the long term it'd
      // be ideal to deal with the phase 0 table as part of the process of
      // converting P4-14 programs to P4-16 TNA programs, and doing that
      // requires that we only rely on frontend IR.

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
      auto key = table->getKey();
      if (key == nullptr) return false;
      if (key->keyElements.size() != 1) return false;
      auto keyElem = key->keyElements[0];
      if (!keyElem->expression->is<IR::Member>()) return false;
      auto member = keyElem->expression->to<IR::Member>();
      auto containingType = typeMap->getType(member->expr, true);
      if (!containingType->is<IR::Type_Declaration>()) return false;
      auto containingTypeDecl = containingType->to<IR::Type_Declaration>();
      if (containingTypeDecl->name != "ingress_intrinsic_metadata_t") return false;
      if (member->member != "ingress_port") return false;

      // The match type must be 'exact'.
      auto matchType = refMap->getDeclaration(keyElem->matchType->path, true)
                             ->to<IR::Declaration_ID>();
      if (matchType->name.name != P4::P4CoreLibrary::instance.exactMatch.name)
          return false;

      return true;
  }

  /// @return true if @expression is a member of a metadata type.
  bool isMetadata(const IR::Expression* expression) const {
      if (!expression->is<IR::Member>()) return false;
      auto member = expression->to<IR::Member>();
      auto containingType = typeMap->getType(member->expr, true);
      return containingType->is<IR::Type_Struct>();
  }

  /// @return true if @expression is a parameter in the parameter list @params.
  bool isParam(const IR::Expression* expression,
               const IR::ParameterList* params) const {
      if (!expression->is<IR::PathExpression>()) return false;
      auto path = expression->to<IR::PathExpression>()->path;
      auto decl = refMap->getDeclaration(path, true);
      if (!decl->is<IR::Parameter>()) return false;
      auto param = decl->to<IR::Parameter>();
      for (auto paramElem : params->parameters)
          if (paramElem == param) return true;
      return false;
  }

  bool hasValidAction(const IR::P4Table* table,
                      Phase0Extracts** extractsOut,
                      Phase0Constants** constantsOut,
                      std::string& actionNameOut) const {
      auto actions = table->getActionList();
      if (actions == nullptr) return false;

      // Other than NoAction, the phase 0 table should have exactly one action.
      const IR::ActionListElement* actionElem = nullptr;
      for (auto elem : actions->actionList) {
          if (elem->getName().name.startsWith("NoAction")) continue;
          if (actionElem != nullptr) return false;
          actionElem = elem;
      }
      if (actionElem == nullptr) return false;

      auto decl = refMap->getDeclaration(actionElem->getPath(), true);
      BUG_CHECK(decl->is<IR::P4Action>(), "Action list element is not an action?");
      auto action = decl->to<IR::P4Action>();

      // Save the action name for assembly output
      actionNameOut = action->getName().name;

      // The action should have only action data parameters.
      for (auto param : *action->parameters)
          if (param->direction != IR::Direction::None) return false;

      *extractsOut = new Phase0Extracts;
      *constantsOut = new Phase0Constants;
      for (auto statement : action->body->components) {
          // The action should contain only assignments.
          if (!statement->is<IR::AssignmentStatement>()) return false;
          auto assignment = statement->to<IR::AssignmentStatement>();

          // The action should write to metadata fields only.
          // XXX(seth): Ideally we'd also verify that it only writes to fields
          // that the parser doesn't already write to.
          if (!isMetadata(assignment->left)) return false;

          // The action should only read from constants or its parameters.
          if (assignment->right->is<IR::Constant>()) {
              (*constantsOut)->emplace(assignment->left->to<IR::Member>(),
                                       assignment->right->to<IR::Constant>());
              continue;
          }
          if (!isParam(assignment->right, action->parameters)) return false;
          (*extractsOut)->emplace(assignment->left->to<IR::Member>(),
                                  assignment->right->to<IR::PathExpression>()
                                                   ->path->name.name);
      }

      return true;
  }

  bool hasValidControlFlow(const IR::P4Table* table,
                           const IR::MethodCallStatement** callOut) const {
      // The phase 0 table should be applied in the control's first statement.
      auto control = findContext<IR::P4Control>();
      if (!control) return false;
      if (control->body->components.size() == 0) return false;
      auto& statements = control->body->components;

      // That statement should be an 'if' statement.
      if (!statements[0]->is<IR::IfStatement>()) return false;
      auto ifStatement = statements[0]->to<IR::IfStatement>();
      if (!ifStatement->condition->is<IR::Equ>()) return false;
      auto equ = ifStatement->condition->to<IR::Equ>();

      // The 'if' should check that 'ingress_intrinsic_metadata.resubmit_flag' is 0.
      auto member = equ->left->to<IR::Member>()
                  ? equ->left->to<IR::Member>()
                  : equ->right->to<IR::Member>();
      auto constant = equ->left->to<IR::Constant>()
                    ? equ->left->to<IR::Constant>()
                    : equ->right->to<IR::Constant>();
      if (member == nullptr || constant == nullptr) return false;
      auto containingType = typeMap->getType(member->expr, true);
      if (!containingType->is<IR::Type_Declaration>()) return false;
      auto containingTypeDecl = containingType->to<IR::Type_Declaration>();
      if (containingTypeDecl->name != "ingress_intrinsic_metadata_t") return false;
      if (member->member != "resubmit_flag") return false;
      if (!constant->fitsInt() || constant->asInt() != 0) return false;

      // The body of the 'if' should consist only of the table apply call.
      if (!ifStatement->ifTrue->is<IR::MethodCallStatement>()) return false;
      *callOut = ifStatement->ifTrue->to<IR::MethodCallStatement>();
      auto mi = P4::MethodInstance::resolve(*callOut, refMap, typeMap);
      if (!mi->isApply() || !mi->to<P4::ApplyMethod>()->isTableApply()) return false;
      if (mi->object != table) return false;

      return true;
  }

  bool preorder(const IR::P4Table*) override {
      if (table != nullptr) return false;

      auto* candidateTable = getOriginal<IR::P4Table>();
      CHECK_NULL(candidateTable);
      LOG3("Checking if " << candidateTable->name << " is a valid phase 0 table");
      Phase0Extracts* extracts = nullptr;
      Phase0Constants* constants = nullptr;
      std::string actionName = "";
      const IR::MethodCallStatement* apply = nullptr;

      // Check if this table meets all of the phase 0 criteria.
      if (!hasCorrectSize(candidateTable)) return false;
      LOG3(" - The size is correct");
      if (!hasNoSideEffects(candidateTable)) return false;
      LOG3(" - It has no side effects");
      if (!hasCorrectKey(candidateTable)) return false;
      LOG3(" - The key is correct");
      if (!hasValidAction(candidateTable, &extracts, &constants, actionName)) return false;
      LOG3(" - The action is valid");
      if (!hasValidControlFlow(candidateTable, &apply)) return false;
      LOG3(" - The control flow is valid");

      BUG_CHECK(apply != nullptr && extracts != nullptr && constants != nullptr,
                "Found a table, but didn't gather all the metadata?");
      LOG3(" - " << candidateTable->name << " will be used as the phase 0 table");
      this->table = candidateTable;
      this->extracts = extracts;
      this->constants = constants;
      this->actionName = actionName;
      this->apply = apply;
      return false;
  }

  bool preorder(const IR::Node*) override {
      // Continue only if we haven't found the phase 0 table yet.
      return table == nullptr;
  }

 public:
  FindPhase0Table(P4::ReferenceMap* refMap, P4::TypeMap* typeMap)
      : refMap(refMap), typeMap(typeMap) { }

  /// If non-null, the phase 0 table we found.
  const IR::P4Table* table = nullptr;
  /// If non-null, the extractions the phase 0 parser needs to perform.
  Phase0Extracts* extracts = nullptr;
  /// If non-null, the constant assignments the phase 0 parser needs to perform.
  Phase0Constants* constants = nullptr;
  /// If non-empty, the action name as specified in the P4 program
  std::string actionName = "";

  /// If non-null, the table apply call that's being replaced with a phase 0 parser.
  const IR::MethodCallStatement* apply = nullptr;

 private:
  P4::ReferenceMap* refMap;
  P4::TypeMap* typeMap;
};

/**
 * Remove the apply() call that invoked the phase 0 table. Note that we
 * don't remove the table itself, since it may be invoked in more than one
 * place. If this was the only usage, it'll be implicitly removed anyway
 * when we generate the backend IR.
 */
class RemovePhase0Table : public Transform {
 public:
  explicit RemovePhase0Table(const IR::MethodCallStatement* apply)
      : apply(apply) { CHECK_NULL(apply); }

 private:
  const IR::Node* preorder(IR::MethodCallStatement* methodCall) override {
      if (getOriginal<IR::MethodCallStatement>() == apply) {
          BUG_CHECK(getParent<IR::IfStatement>() != nullptr,
                    "Expected apply call for phase 0 table to be the body of "
                    "an 'if' statement");
          return new IR::BlockStatement;
      }
      return methodCall;
  }

  const IR::MethodCallStatement* apply;
};

/**
 * @return an assignment of the phase 0 extracted fields to ranges of bits in
 * the phase 0 data. This is used to generate the parser program and to
 * generate assembly that tells the driver how to set up the phase 0 data.
 */
FieldPacking* packPhase0Fields(const Phase0Extracts* extracts) {
    auto* packing = new FieldPacking;

    for (auto extractItem : *extracts) {
        const IR::Member* dest = extractItem.first;
        cstring source = extractItem.second;
        auto containingType = dest->expr->type;
        BUG_CHECK(containingType->is<IR::Type_StructLike>(),
                  "Phase 0 field is not attached to a structlike type?");
        auto type = containingType->to<IR::Type_StructLike>();

        auto field = type->getField(dest->member);
        BUG_CHECK(field != nullptr,
                  "Phase 0 field %1% not found in type %2%", field, type);
        packing->appendField(dest, source, field->type->width_bits());
        packing->padToAlignment(8);
    }

    packing->padToAlignment(Device::pardeSpec().bitPhase0Size());
    return packing;
}

/**
 * Replaces the placeholder '$phase0' parser state with a sequence of states
 * that extracts all the fields in the phase 0 data and performs any constant
 * assignments which are necessary.
 */
class AddPhase0Parser : public Modifier {
 public:
  AddPhase0Parser(const FieldPacking* packing, const Phase0Constants* constants)
      : packing(packing), constants(constants)
  { }

  bool preorder(IR::BFN::Parser* parser) {
      if (parser->gress != INGRESS) return false;

      auto start = transformAllMatching<IR::BFN::ParserState>(parser->start,
                   [this](const IR::BFN::ParserState* state) {
          if (state->name != "$phase0") return state;

          // This is the '$phase0' placeholder state. We'll replace it with our
          // generated parser program. After phase 0, we'll transition to the
          // same state that the placeholder state transitioned to, which is
          // normally 'start$'.
          return this->addPhase0State(state->transitions[0]->next);
      });

      parser->start = start->to<IR::BFN::ParserState>();
      return false;
  }

  const IR::BFN::ParserState*
  addPhase0State(const IR::BFN::ParserState* finalState) {
      // Generate a state that extracts the packed fields.
      auto* nextState =
        packing->createExtractionState(INGRESS, "$phase0_extract", finalState);

      // Generate a state which extracts the constants.
      IR::Vector<IR::BFN::ParserPrimitive> extracts;
      for (auto& constantItem : *constants) {
          auto* dest = constantItem.first;
          auto constant = constantItem.second->value;
          auto* extract =
            new IR::BFN::Extract(dest, new IR::BFN::ConstantRVal(constant));
          extracts.push_back(extract);
      }

      return new IR::BFN::ParserState("$phase0", INGRESS, extracts, { }, {
          new IR::BFN::Transition(match_t(), 0, nextState)
      });
  }

 private:
  const FieldPacking* packing;
  const Phase0Constants* constants;
};

std::pair<const IR::P4Control*, IR::BFN::Pipe*>
extractPhase0(const IR::P4Control* ingress, IR::BFN::Pipe* pipe,
              P4::ReferenceMap* refMap, P4::TypeMap* typeMap) {
    CHECK_NULL(ingress);
    CHECK_NULL(pipe);
    CHECK_NULL(refMap);
    CHECK_NULL(typeMap);

    // Find and remove the phase 0 table, if it's present.
    FindPhase0Table findPhase0(refMap, typeMap);
    ingress->apply(findPhase0);
    if (findPhase0.table == nullptr) return std::make_pair(ingress, pipe);
    auto ingressWithoutPhase0 =
      ingress->apply(RemovePhase0Table(findPhase0.apply));

    // Attempt to pack the fields we'll need to extract in the phase 0 parser
    // into the available phase 0 space. This may fail.
    auto packing = packPhase0Fields(findPhase0.extracts);
    if (packing->totalWidth != Device::pardeSpec().bitPhase0Size())
        return std::make_pair(ingress, pipe);

    // Create the phase 0 parser and link it into place in the existing parser
    // program.
    AddPhase0Parser addPhase0Parser(packing, findPhase0.constants);
    pipe->thread[INGRESS].parser =
        pipe->thread[INGRESS].parser->apply(addPhase0Parser);

    pipe->phase0Info = new Phase0Info{findPhase0.table, packing, findPhase0.actionName};
    return std::make_pair(ingressWithoutPhase0, pipe);
}

}  // namespace BFN
