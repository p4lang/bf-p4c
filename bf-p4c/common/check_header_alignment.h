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

#ifndef BF_P4C_COMMON_CHECK_HEADER_ALIGNMENT_H_
#define BF_P4C_COMMON_CHECK_HEADER_ALIGNMENT_H_

#include "ir/ir.h"

namespace P4 {
class TypeMap;
}  // namespace P4

namespace BFN {

/**
 * Check for non-byte-aligned header types and report an error if any are found.
 *
 * On Tofino, we can only parse and deparse byte-aligned headers, so
 * non-byte-aligned headers aren't useful.
 *
 * XXX(seth): We could theoretically allow non-byte-aligned headers if they're
 * only used in the MAU, but for now I've avoided that since it seems less
 * confusing for the P4 programmer to have a simple and clear rule.
 */
class CheckHeaderAlignment final : public Inspector {
    P4::TypeMap* typeMap;

 private:
    bool preorder(const IR::Type_Header* header) override;

 public:
    explicit CheckHeaderAlignment(P4::TypeMap* typeMap) : typeMap(typeMap) {}
};

}  // namespace BFN

#endif  /* BF_P4C_COMMON_CHECK_HEADER_ALIGNMENT_H_ */
