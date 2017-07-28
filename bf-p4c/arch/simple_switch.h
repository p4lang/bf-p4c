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

#ifndef TOFINO_ARCH_SIMPLE_SWITCH_H_
#define TOFINO_ARCH_SIMPLE_SWITCH_H_

#include "ir/ir.h"
#include "tofino/tofinoOptions.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "tofino/arch/converters.h"
#include "tofino/arch/program_structure.h"

namespace Tofino {

/// A simple switch program uses 'v1model.p4' as target architecture, the following
/// passes translate a v1model program to the equivalent program targeting tofino.p4.
// XXX(hanw): SimpleSwitchTranslator is an instance of a generic architecture
// translation pass, which should be added in public p4c code base.
class SimpleSwitchTranslator : public PassManager {
    // the core data structure to run all transform passes on.
    ProgramStructure* structure = new ProgramStructure();

 public:
    explicit SimpleSwitchTranslator(const Tofino_Options* options);
    Visitor::profile_t init_apply(const IR::Node* node) {
        BUG_CHECK(node->is<IR::P4Program>(),
                  "Simple switch translator only accepts IR::P4Program.");
        return PassManager::init_apply(node);
    }
};

/// translate extern
class ConvertControl : public Transform {
    ProgramStructure* structure;

 public:
    explicit ConvertControl(ProgramStructure* structure)
        : structure(structure) { CHECK_NULL(structure); setName("ConvertControl"); }

    const IR::Node* postorder(IR::P4Control* node);
    const IR::Node* postorder(IR::P4Action* action);
    void translateParam(const IR::Parameter* param, cstring name,
                        IR::ParameterList* apply_params);
};

/// @input P4-16 parser for simple switch
/// @output P4-16 parser for tofino model
class ConvertParser : public Transform {
 protected:
    ProgramStructure* structure;
    gress_t gress;

 public:
    explicit ConvertParser(ProgramStructure* structure, gress_t gress)
        : structure(structure), gress(gress)
    { CHECK_NULL(structure); setName("ConvertParser"); }
    const IR::Node* postorder(IR::P4Parser* node);
    const IR::Node* postorder(IR::ParserState* node);
    const IR::Node* postorder(IR::Type_Parser* node);
    const IR::Node* postorder(IR::Declaration* node);
};

class ConvertDeparser : public Transform {
    ProgramStructure* structure;
    gress_t gress;
 public:
    explicit ConvertDeparser(ProgramStructure* structure, gress_t gress)
        : structure(structure), gress(gress)
    { CHECK_NULL(structure); setName("ConvertDeparser"); }
    const IR::Node* postorder(IR::P4Control* node);
    const IR::Node* postorder(IR::Type_Control* node);
};

class ConvertMetadata : public Transform {
    ProgramStructure* structure;
    gress_t gress;
    std::map<std::pair<cstring, cstring>, std::pair<cstring, cstring>> remap = {
        { { "standard_metadata", "ingress_port" }, { "ig_intr_md", "ingress_port" } },
        { { "standard_metadata", "resubmit_flag" }, { "ig_intr_md", "resubmit_flag" } },
        { { "standard_metadata", "egress_spec" },
            { "ig_intr_md_for_tm", "ucast_egress_port" } },
        { { "standard_metadata", "egress_port" }, { "eg_intr_md", "egress_port" } },
        // remap more standard_metadata
    };

 public:
    explicit ConvertMetadata(ProgramStructure* structure)
        : structure(structure) { CHECK_NULL(structure); setName("ConvertMetadata"); }
    const IR::Node* postorder(IR::AssignmentStatement* node);
    const IR::Node* preorder(IR::Member* node);
    const IR::Node* preorder(IR::StructField* node);
};

const IR::P4Program* translateSimpleSwitch(const IR::P4Program* program,
                                           const Tofino_Options* options,
                                           boost::optional<DebugHook> debugHook);
}  // namespace Tofino

#endif /* TOFINO_ARCH_SIMPLE_SWITCH_H_ */
