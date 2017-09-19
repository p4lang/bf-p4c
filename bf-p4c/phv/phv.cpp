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

#include "bf-p4c/phv/phv.h"

#include <array>
#include <cstring>
#include <iostream>
#include <sstream>

#include "lib/bitvec.h"
#include "lib/exceptions.h"
#include "lib/cstring.h"

namespace PHV {

Container::Container(const char *name) {
    const char *n = name + strcspn(name, "0123456789");
    type_ = Type(std::string(name, n - name).c_str());

    char *end = nullptr;
    auto v = strtol(n, &end, 10);
    index_ = v;
    if (end == n || *end || index_ != v)
        BUG("Invalid register '%s'", name);
}

cstring Container::toString() const {
    std::stringstream tmp;
    tmp << *this;
    return tmp.str();
}

/* static */ cstring Container::groupToString(const bitvec& group) {
    bool first = true;
    std::stringstream groupAsString;
    for (auto member : group) {
        if (!first) groupAsString << ", ";
        first = false;
        groupAsString << fromId(member);
    }
    return cstring(groupAsString);
}

std::ostream& operator<<(std::ostream& out, const PHV::Container c) {
    return out << c.type() << c.index();
}

std::ostream& operator<<(std::ostream& out, ordered_set<const PHV::Container *>& c_set) {
    out << "{";
    for (auto &c : c_set) {
        out << *c << ",";
    }
    out << "}";
    return out;
}

}  // namespace PHV
