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

#ifndef TOFINO_MIDEND_H_
#define TOFINO_MIDEND_H_

#include "ir/ir.h"
#include "frontends/common/options.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "midend/actionsInlining.h"
#include "midend/inlining.h"

namespace BFN {

class MidEnd : public PassManager {
    P4::InlineWorkList controlsToInline;
    P4::ActionsInlineList actionsToInline;

 public:
    // These will be accurate when the mid-end completes evaluation
    P4::ReferenceMap    refMap;
    P4::TypeMap         typeMap;
    IR::ToplevelBlock   *toplevel = nullptr;  // Should this be const?

    explicit MidEnd(CompilerOptions& options);
};

}  // namespace BFN

#endif /* TOFINO_MIDEND_H_ */
