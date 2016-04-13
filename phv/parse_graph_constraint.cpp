#include "parse_graph_constraint.h"
#include "phv.h"
#include "constraints.h"
#include <base/logging.h>

void ParseGraphConstraint::postorder(const IR::Tofino::ParserMatch *pm) {
  decltype(local_extracts_)::iterator new_item;
  bool is_inserted;
  std::tie(new_item, is_inserted) = local_extracts_.insert(
                                      std::make_pair(pm, PHV::Bits(0)));
  CHECK(true == is_inserted) << ": Key already exists for " << *pm;
  // We need to iterate through all the statements to figure out which PHV
  // containers were populated in pm. We cannot write a visitor for this
  // because multiple ParserMatch objects might contain a pointer to the same
  // extract primitive.
  for (auto it : pm->stmts) {
    const IR::Primitive *prim = it->to<IR::Primitive>();
    // FIXME: Need to handle set_metadata here.
    if (nullptr != prim && prim->name == "extract") {
      for (auto &b : GetBytes(prim->operands[0])) {
        CheckAndAppendBits(b.bits(), &(new_item->second));
      }
    }
    CHECK(new_item->second.size() % 8 == 0) << ": Bad extraction in " << *prim;
  }
  LOG2("Found " << (new_item->second.size() >> 3) << "B in " << *pm);
  PHV::Bits old_bits(0);
  if (nullptr != pm->next) {
    CHECK(subtree_extracts_.count(pm->next->name) != 0) <<
      ": Cannot find extracts in " << *(pm->next->name);
    old_bits = subtree_extracts_.at(pm->next->name);
    LOG2("Setting conflicts from " <<
           findContext<const IR::Tofino::ParserState>()->name << " to " <<
           pm->next->name);
  }
  // We need to call this function even if there is no next state. Otherwise,
  // there is no way to set conflicts between bits extracted in this
  // ParserMatch.
  // TODO: After adding support for set_metadata(), SetParseConflict will also
  // need to be modified because we do not want to add a bit-conflict (or
  // container-conflict) between pkt.f1 and meta.f2 when we do
  // set_metadata(meta.f2, pkt.f1);
  constraints_.SetParseConflict(old_bits, new_item->second);
}

void ParseGraphConstraint::postorder(const IR::Tofino::ParserState *ps) {
  LOG2("Creating subtree entry for " << ps->name);
  CHECK(subtree_extracts_.count(ps->name) == 0) << ": " << *ps <<
          " already exists ";
  subtree_extracts_.insert(std::make_pair(ps->name, PHV::Bits(0)));
  PHV::Bits *bits = &subtree_extracts_.at(ps->name);
  for (const IR::Tofino::ParserMatch *pm : ps->match) {
    CHECK(nullptr != pm) << ": Found nullptr match in " << *ps;
    if (0 != local_extracts_.count(pm)) {
      CheckAndAppendBits(local_extracts_.at(pm), bits);
    }
    if (nullptr != pm->next) {
      LOG2("Inserting bits from " << pm->next->name << " to " << ps->name);
      CheckAndAppendBits(subtree_extracts_.at(pm->next->name), bits);
    }
  }
}

void ParseGraphConstraint::CheckAndAppendBits(const PHV::Bits &new_bits,
                                              PHV::Bits *bits) {
  CHECK(new_bits.size() % 8 == 0) << ": Bad size " << new_bits.size();
  auto it = new_bits.cbegin();
  while (it != new_bits.cend()) {
    auto it_next = std::next(it, 8);
    auto res = std::search(bits->begin(), bits->end(), it, it_next);
    if (res == bits->end()) {
      bits->insert(bits->end(), it, it_next);
    }
    it = it_next;
  }
}
