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

#ifndef EXTENSIONS_TOFINO_ARCH_CONVERTERS_H_
#define EXTENSIONS_TOFINO_ARCH_CONVERTERS_H_

#include "ir/ir.h"
#include "tofino/arch/program_structure.h"

namespace P4 {

// ExpressionConverter can be used in many places
class ExpressionConverter : public Transform {
 protected:
    ProgramStructure* structure;
 public:
    explicit ExpressionConverter(ProgramStructure* structure)
        : structure(structure) { CHECK_NULL(structure); setName("ExpressionConverter"); }
    const IR::Node* postorder(IR::Member* node);
};

// StatementConverter can be used in ConvertControl, ConvertDeparser ...
class StatementConverter : public ExpressionConverter {
 public:
    explicit StatementConverter(ProgramStructure* structure)
        : ExpressionConverter(structure) {}
    const IR::Node* postorder(IR::AssignmentStatement* node);
    const IR::Node* postorder(IR::IfStatement* node);
};

class TypeConverter : public ExpressionConverter {
 public:
    explicit TypeConverter(ProgramStructure* structure)
        : ExpressionConverter(structure) { CHECK_NULL(structure); setName("TypeConverter"); }

    const IR::Node* postorder(IR::Declaration_Instance* node) override {
        if (node->name == "V1Switch") {
            // make a new switch
        }
        return node;
    }
};

class ExternConverter {
    static std::map<cstring, ExternConverter*> *cvtForType;

 public:
    virtual const IR::Type_Extern* convertExternType(ProgramStructure *,
            const IR::Type_Extern* ext, cstring) { return ext; }
    ExternConverter() {}
    static void addConverter(cstring type, ExternConverter*);
    static ExternConverter* get(cstring type);
    static ExternConverter* get(const IR::Type_Extern* type) { return get(type->name); }
    static ExternConverter* get(const IR::Declaration_Instance *ext) {
        return get(ext->type->to<IR::Type_Extern>()); }
};

class CounterExternConverter : public ExternConverter {
    static CounterExternConverter instance;
 public:
    CounterExternConverter();
    const IR::Type_Extern* convertExternType(ProgramStructure*,
            const IR::Type_Extern*, cstring) override;
};

}  // namespace P4

#endif  /* EXTENSIONS_TOFINO_ARCH_CONVERTERS_H_ */

