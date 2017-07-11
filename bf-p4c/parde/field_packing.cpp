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

#include "tofino/parde/field_packing.h"

#include <boost/range/iterator_range_core.hpp>

#include "ir/ir.h"
#include "lib/cstring.h"

namespace Tofino {

void FieldPacking::appendField(const IR::Expression* field, unsigned width) {
    appendField(field, cstring(), width);
}

void FieldPacking::appendField(const IR::Expression* field, cstring source,
                               unsigned width) {
    BUG_CHECK(field != nullptr, "Packing null field?");
    fields.push_back({field, source, width});
    totalWidth += width;
}

void FieldPacking::appendPadding(unsigned width) {
    if (!fields.empty() && fields.back().isPadding()) {
        fields.back().width += width;
    } else {
        fields.push_back({nullptr, cstring(), width});
    }
    totalWidth += width;
}

void FieldPacking::append(const FieldPacking& packing) {
    for (auto item : packing.fields) {
        if (item.isPadding())
            appendPadding(item.width);
        else
            appendField(item.field, item.source, item.width);
    }
}

void FieldPacking::padToAlignment(unsigned alignment) {
    if (isAlignedTo(alignment)) return;
    appendPadding(alignment - totalWidth % alignment);
}

void FieldPacking::clear() {
    fields.clear();
    totalWidth = 0;
}

bool FieldPacking::containsFields() const {
    for (auto item : fields)
        if (!item.isPadding()) return true;
    return false;
}

bool FieldPacking::isAlignedTo(unsigned alignment) const {
    return totalWidth % alignment == 0;
}

namespace {

struct FieldGroupParser {
  FieldGroupParser(const FieldPacking* packing, gress_t gress,
                   cstring baseStateName,
                   const IR::Tofino::ParserState* finalState)
    : packing(packing), gress(gress), baseStateName(baseStateName),
      finalState(finalState)
  { }

  const IR::Tofino::ParserState* create() {
      return createStateForGroup(packing->begin());
  }

 private:
  const IR::Tofino::ParserState*
  createStateForGroup(FieldPacking::const_iterator groupBegin) {
      // If we've extracted all of the packed fields, we're done; just return
      // the final state of the chain, which is normally 'start$'.
      if (groupBegin == packing->end()) return finalState;

      auto stateName = cstring::make_unique(uniqueStateNames, baseStateName);
      uniqueStateNames.insert(stateName);

      // This state will extract a group of packed fields. Consume fields until
      // we encounter padding.
      unsigned shiftBits = 0;
      auto groupIter = groupBegin;
      while (groupIter != packing->end() && !groupIter->isPadding()) {
          shiftBits += groupIter->width;
          ++groupIter;
      }
      auto groupEnd = groupIter;

      // Consume padding. We don't need to extract it, but we do need to shift
      // over it when we transition to the next state.
      while (groupIter != packing->end() && groupIter->isPadding()) {
          shiftBits += groupIter->width;
          ++groupIter;
      }
      auto nextGroupBegin = groupIter;
      BUG_CHECK(shiftBits % 8 == 0, "Non-byte-aligned shift?");

      // There may be more groups. Recursively construct the states for those
      // groups first so we can hook them into the chain of states.
      auto nextState = createStateForGroup(nextGroupBegin);

      // Generate a state that extracts all the fields in the group.
      IR::Vector<IR::Expression> statements;
      for (auto& item : boost::make_iterator_range(groupBegin, groupEnd))
          statements.push_back(new IR::Primitive("extract", item.field));

      auto match = new IR::Tofino::ParserMatch(match_t(), statements);
      match->shift = shiftBits / 8;
      match->next = nextState;
      return new IR::Tofino::ParserState(stateName, gress, { }, { match });
  }

  const FieldPacking* packing;
  gress_t gress;
  cstring baseStateName;
  const IR::Tofino::ParserState* finalState;
  set<cstring> uniqueStateNames;
};

}  // namespace

const IR::Tofino::ParserState*
FieldPacking::createExtractionStates(gress_t gress, cstring baseStateName,
                                     const IR::Tofino::ParserState* finalState) const {
    return FieldGroupParser(this, gress, baseStateName, finalState).create();
}

}  // namespace Tofino

std::ostream& operator<<(std::ostream& out, const Tofino::FieldPacking* packing) {
    if (packing == nullptr) {
        out << "(null field packing)" << std::endl;
        return out;
    }

    out << "Field packing: {" << std::endl;
    for (auto item : packing->fields) {
        if (item.isPadding())
            out << " - (padding) ";
        else
            out << " - " << item.field << " = " << item.source << " ";
        out << "(width: " << item.width << " bits)" << std::endl;
    }
    out << "} (total width: " << packing->totalWidth << " bits)" << std::endl;
    return out;
}
