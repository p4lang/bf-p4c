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
    const char *n = name;
    if (*name == 'T') {
        tagalong_ = true;
        n++;
    } else {
        tagalong_ = false; }
    switch (*n++) {
    case 'B': log2sz_ = 0; break;
    case 'H': log2sz_ = 1; break;
    case 'W': log2sz_ = 2; break;
    default: BUG("Invalid register '%s'", name); }
    char *end = nullptr;
    int v = strtol(n, &end, 10);
    index_ = v;
    if (end == n || *end || index_ != v)
        BUG("Invalid register '%s'", name);
}

Container::Container(Kind kind, unsigned index) {
    index_ = index;
    switch (kind) {
      case Kind::B: log2sz_ = 0; tagalong_ = false; return;
      case Kind::H: log2sz_ = 1; tagalong_ = false; return;
      case Kind::W: log2sz_ = 2; tagalong_ = false; return;
      case Kind::TB: log2sz_ = 0; tagalong_ = true; return;
      case Kind::TH: log2sz_ = 1; tagalong_ = true; return;
      case Kind::TW: log2sz_ = 2; tagalong_ = true; return;
    }
    BUG("Unexpected kind");
}

Kind Container::kind() const {
    switch (log2sz_) {
      case 0: return tagalong_ ? Kind::TB : Kind::B;
      case 1: return tagalong_ ? Kind::TH : Kind::H;
      case 2: return tagalong_ ? Kind::TW : Kind::W;
      default: BUG("Called kind() on an invalid container");
    }
}

bitvec Container::group() const {
    const auto containerKind = kind();

    // Individually assigned containers aren't part of a group, by definition.
    if (individuallyAssignedContainers()[id()])
        return range(containerKind, index_, 1);

    // We also treat overflow containers (i.e., containers which don't exist in
    // hardware) as being individually assigned.
    if (!physicalContainers()[id()])
        return range(containerKind, index_, 1);

    // Outside of the exceptional cases above, containers are assigned to
    // threads in groups. The grouping depends on the type of container.
    switch (containerKind) {
      case Kind::B:
      case Kind::H:
        return range(containerKind, (index_ / 8) * 8, 8);

      case Kind::W:
        return range(containerKind, (index_ / 4) * 4, 4);

      case Kind::TB:
      case Kind::TW:
        return tagalongGroup(index_ / 4);

      case Kind::TH:
        return tagalongGroup(index_ / 6);
    }

    BUG("Unexpected PHV container kind %1%", containerKind);
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
    return out << c.kind() << c.index_;
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
