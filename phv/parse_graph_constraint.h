#ifndef TOFINO_PHV_PARSE_GRAPH_CONSTRAINT_H_
#define TOFINO_PHV_PARSE_GRAPH_CONSTRAINT_H_
#include <unordered_map>
#include "tofino/parde/parde_visitor.h"
#include "bit_extractor.h"
class Constraints;
class ParseGraphConstraint : public PardeInspector, public BitExtractor {
 public:
    ParseGraphConstraint(const PhvInfo &phv, Constraints &c)
    : BitExtractor(phv), constraints_(c) { }
 private:
    // This function inserts parse conflicts between all its local extracts and
    // extracts reachable from ParserMatch::next.
    void postorder(const IR::Tofino::ParserMatch *pm) override;
    // This function creates an entry for ps in the subtree_extracts_ map. The
    // value for that entry is composed from all its ParserMatch entries in
    // local_extracts_ and their next entries in subtree_extracts_.
    void postorder(const IR::Tofino::ParserState *ps) override;
    // This function adds new_bits into bits if they are not already present.
    void CheckAndAppendBits(const PHV::Bits &new_bits, PHV::Bits *bits);
    // The key is the name of a parse state (ParserState::name). The value
    // contains all the bits that might be extracted in this parse state or any
    // parse state reachable from it.
    std::unordered_map<cstring, PHV::Bits> subtree_extracts_;
    // Each item contains the bits extracted in its ParserMatch object.
    std::unordered_map<const IR::Tofino::ParserMatch*, PHV::Bits> local_extracts_;
    Constraints &constraints_;
};
#endif /* TOFINO_PHV_PARSE_GRAPH_CONSTRAINT_H_ */
