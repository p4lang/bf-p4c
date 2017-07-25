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

#include "ir/ir.h"
#include "tofino/arch/converters.h"

namespace P4 {

std::map<cstring, ExternConverter *> *ExternConverter::cvtForType = nullptr;

void ExternConverter::addConverter(cstring type, ExternConverter *cvt) {
    static std::map<cstring, ExternConverter *> tbl;
    cvtForType = &tbl;
    tbl[type] = cvt;
}

ExternConverter *ExternConverter::get(cstring type) {
    static ExternConverter default_cvt;
    if (cvtForType && cvtForType->count(type))
        return cvtForType->at(type);
    return &default_cvt;
}

// TBD: separate extern converter for each extern type
// TODO: redesign CounterExternConverter
CounterExternConverter::CounterExternConverter() {
    addConverter("counter", this);
}

const IR::Type_Extern* CounterExternConverter::convertExternType(ProgramStructure*,
        const IR::Type_Extern* ext, cstring) {
    return ext;
}

CounterExternConverter CounterExternConverter::instance;

const IR::Node* ExpressionConverter::postorder(IR::Member* member) {
    // XXX(hanw): standard_metadata is already remapped.
    return member;
}

const IR::Node* StatementConverter::postorder(IR::AssignmentStatement* node) {
    ExpressionConverter cvt(structure);
    auto left = node->left->apply(cvt);
    auto right = node->right->apply(cvt);
    auto result = new IR::AssignmentStatement(node->srcInfo, left, right);
    return result;
}

const IR::Node* StatementConverter::postorder(IR::IfStatement* node) {
    StatementConverter cvt(structure);
    // use ExpressionConverter to convert node->condition
    const IR::Statement *t, *f;
    if (node->ifTrue == nullptr) {
        t = new IR::EmptyStatement();
    } else {
        t = node->ifTrue->apply(cvt)->to<IR::Statement>();
    }
    if (node->ifFalse == nullptr) {
        f = nullptr;
    } else {
        f = node->ifFalse->apply(cvt)->to<IR::Statement>();
    }
    prune();
    auto result = new IR::IfStatement(node->srcInfo, node->condition, t, f);
    return result;
}

}  // namespace P4
