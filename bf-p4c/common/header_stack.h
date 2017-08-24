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

#ifndef TOFINO_COMMON_HEADER_STACK_H_
#define TOFINO_COMMON_HEADER_STACK_H_

#include "ir/ir.h"
#include "lib/map.h"

/// Walk over the IR and collect metadata about the usage of header stacks in
/// the program. The results are stored in `IR::Tofino::Pipe::headerStackInfo`.
struct CollectHeaderStackInfo : public Modifier {
    CollectHeaderStackInfo();

 private:
    void postorder(IR::HeaderStack* stack) override;
    void postorder(IR::Primitive* primitive) override;
    void postorder(IR::Tofino::Pipe* pipe) override;

    Tofino::HeaderStackInfo* stacks;
};

namespace Tofino {

/// Metadata about how header stacks are used in the program.
struct HeaderStackInfo {
    struct Info {
        /// The name of the header stack this metadata describes.
        cstring name;

        /// Which threads is this header stack visible in? By default, the same
        /// header stack is used in both threads, but after
        /// CreateThreadLocalInstances runs, header stacks are thread-specific.
        bool inThread[2] = { true, true };

        /// How many elements are in this header stack?
        int size = 0;

        /// What is the maximum number of elements that are pushed onto this
        /// header stack in a single `push_front` primitive invocation?
        int maxpush = 0;

        /// What is the maximum number of elements that are popped off of this
        /// header stack in a single `pop_front` primitive invocation?
        int maxpop = 0;
    };

 private:
    friend struct ::CollectHeaderStackInfo;
    std::map<cstring, Info> info;

 public:
    auto begin() const -> decltype(Values(info).begin()) { return Values(info).begin(); }
    auto begin() -> decltype(Values(info).begin()) { return Values(info).begin(); }
    auto end() const -> decltype(Values(info).end()) { return Values(info).end(); }
    auto end() -> decltype(Values(info).end()) { return Values(info).end(); }
    auto at(cstring n) const -> decltype(info.at(n)) { return info.at(n); }
    auto at(cstring n) -> decltype(info.at(n)) { return info.at(n); }
};

}  // namespace Tofino

#endif /* TOFINO_COMMON_HEADER_STACK_H_ */
