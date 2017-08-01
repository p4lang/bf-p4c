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

#ifndef TOFINO_COMMON_REWRITE_H_
#define TOFINO_COMMON_REWRITE_H_

#include "ir/ir.h"

namespace P4 {
class BuiltInMethod;
class ExternMethod;
class ReferenceMap;
class TypeMap;
}  // namespace P4

struct RewriteForTofino : public Transform {
    RewriteForTofino(P4::ReferenceMap* refMap, P4::TypeMap* typeMap)
        : refMap(refMap), typeMap(typeMap) { }

 private:
    const IR::Expression* postorder(IR::MethodCallExpression* call) override;
    const IR::Expression* postorder(IR::Slice* slice) override;

    const IR::Expression* convertExternMethod(const IR::MethodCallExpression* call,
                                              const P4::ExternMethod* externMethod);
    const IR::Expression* convertBuiltInMethod(const IR::MethodCallExpression* call,
                                               const P4::BuiltInMethod* builtin);

    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;
};

#endif /* TOFINO_COMMON_REWRITE_H_ */
