/*
Copyright 2013-present Barefoot Networks, Inc. 

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include "tofino/parde/phase0.h"

#include <algorithm>
#include "frontends/p4/coreLibrary.h"
#include "frontends/p4/fromv1.0/v1model.h"
#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/indent.h"
#include "tofino/parde/field_packing.h"

std::ostream& operator<<(std::ostream& out, const Tofino::Phase0Info* info) {
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
    out <<   indent << "width: 1" << std::endl;

    // Write out the field packing format. We have to convert into the LSB-first
    // representation that the assembler uses.
    BUG_CHECK(info->packing->totalWidth == 64,
              "Expected phase 0 field packing to allocate exactly 64 bits");
    bool wroteAtLeastOneField = false;
    int msb = 63;
    out << indent << "format: {";
    for (auto& field : *info->packing) {
        BUG_CHECK(field.width > 0, "Empty phase 0 field?");
        BUG_CHECK(msb >= 0, "Phase 0 field starts past 64 bit boundary");
        if (!field.isPadding()) {
            if (wroteAtLeastOneField) out << ", ";
            wroteAtLeastOneField = true;
            int lsb = msb - field.width + 1;
            BUG_CHECK(lsb >= 0, "Phase 0 field overflowed 64 bits");
            out << field.source << ": " << lsb;
            if (msb != lsb) out << ".." << msb;
        }
        msb -= field.width;
    }
    out << "}" << std::endl;

    // Write out the constant value. This is a 64-bit value which is used by the
    // driver to initialize the phase 0 data before the bits assigned to fields
    // are given their user-provided values. Having this available gives us a
    // little more flexibility when packing phase 0 fields.
    // XXX(seth): The above isn't actually implemented, but it's planned. Right
    // now, the driver acts as if this is always set to zero.
    out << indent << "constant_value: 0" << std::endl;

    return out;
}

namespace Tofino {

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
      // The phase 0 table must match against 'standard_metadata.ingress_port'.
      auto key = table->getKey();
      if (key == nullptr) return false;
      if (key->keyElements.size() != 1) return false;
      auto keyElem = key->keyElements[0];
      if (!keyElem->expression->is<IR::Member>()) return false;
      auto member = keyElem->expression->to<IR::Member>();
      auto containingType = typeMap->getType(member->expr, true);
      if (!containingType->is<IR::Type_Declaration>()) return false;
      auto containingTypeDecl = containingType->to<IR::Type_Declaration>();
      if (containingTypeDecl->name != "standard_metadata_t") return false;
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
                      Phase0Constants** constantsOut) const {
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

      // The 'if' should check that 'standard_metadata.resubmit_flag' is 0.
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
      if (containingTypeDecl->name != "standard_metadata_t") return false;
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

      auto candidateTable = getOriginal<IR::P4Table>();
      CHECK_NULL(candidateTable);
      Phase0Extracts* extracts = nullptr;
      Phase0Constants* constants = nullptr;
      const IR::MethodCallStatement* apply = nullptr;

      // Check if this table meets all of the phase 0 criteria.
      if (!hasCorrectSize(candidateTable)) return false;
      if (!hasNoSideEffects(candidateTable)) return false;
      if (!hasCorrectKey(candidateTable)) return false;
      if (!hasValidAction(candidateTable, &extracts, &constants)) return false;
      if (!hasValidControlFlow(candidateTable, &apply)) return false;

      BUG_CHECK(apply != nullptr && extracts != nullptr && constants != nullptr,
                "Found a table, but didn't gather all the metadata?");
      this->table = candidateTable;
      this->extracts = extracts;
      this->constants = constants;
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

    packing->padToAlignment(64);
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

  bool preorder(IR::Tofino::Parser* parser) {
      if (parser->gress != INGRESS) return false;

      auto start = transformAllMatching<IR::Tofino::ParserState>(parser->start,
                   [this](const IR::Tofino::ParserState* state) {
          if (state->name != "$phase0") return state;

          // This is the '$phase0' placeholder state. We'll replace it with our
          // generated parser program. After phase 0, we'll transition to the
          // same state that the placeholder state transitioned to, which is
          // normally 'start$'.
          return this->addPhase0State(state->match[0]->next);
      });

      parser->start = start->to<IR::Tofino::ParserState>();
      return false;
  }

  const IR::Tofino::ParserState*
  addPhase0State(const IR::Tofino::ParserState* finalState) {
      // Generate a state that extracts the packed fields.
      auto nextState =
        packing->createExtractionState(INGRESS, "$phase0_extract", finalState);

      // Generate a state which extracts the constants.
      IR::Vector<IR::Tofino::ParserPrimitive> extracts;
      for (auto constantItem : *constants) {
          auto dest = constantItem.first;
          auto constant = constantItem.second;
          auto extract = new IR::Tofino::ExtractConstant(dest, constant);
          extracts.push_back(extract);
      }

      auto phase0Match =
          new IR::Tofino::ParserMatch(match_t(), 0, extracts, nextState);
      return new IR::Tofino::ParserState("$phase0", INGRESS, { }, { phase0Match });
  }

 private:
  const FieldPacking* packing;
  const Phase0Constants* constants;
};

std::pair<const IR::P4Control*, IR::Tofino::Pipe*>
extractPhase0(const IR::P4Control* ingress, IR::Tofino::Pipe* pipe,
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
    // into 64 bits. This may fail.
    auto packing = packPhase0Fields(findPhase0.extracts);
    if (packing->totalWidth != 64) return std::make_pair(ingress, pipe);

    // Create the phase 0 parser and link it into place in the existing parser
    // program.
    AddPhase0Parser addPhase0Parser(packing, findPhase0.constants);
    pipe->thread[INGRESS].parser =
        pipe->thread[INGRESS].parser->apply(addPhase0Parser);

    pipe->phase0Info = new Phase0Info{findPhase0.table, packing};
    return std::make_pair(ingressWithoutPhase0, pipe);
}

}  // namespace Tofino
