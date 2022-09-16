#ifndef EXTENSIONS_BF_P4C_PARDE_CLOT_CLOT_CANDIDATE_H_
#define EXTENSIONS_BF_P4C_PARDE_CLOT_CLOT_CANDIDATE_H_

#include "bf-p4c/lib/cmp.h"
#include "clot_info.h"
#include "pseudoheader.h"

using StatePair = std::pair<const IR::BFN::ParserState*, const IR::BFN::ParserState*>;
using StatePairSet = ordered_set<StatePair>;

class FieldSliceExtractInfo;

class ClotCandidate : public LiftLess<ClotCandidate> {
 public:
    const Pseudoheader* pseudoheader;
    PovBitSet pov_bits;

 private:
    /// Information relating to the extracts of the candidate's field slices, ordered by position
    /// in the packet.
    // Invariant: field slices are extracted in the same set of parser states.
    const std::vector<const FieldSliceExtractInfo*> extract_infos;

    /// The indices into @ref extract_infos that correspond to field slices that can start a CLOT,
    /// in ascending order.
    std::vector<unsigned> can_start_indices_;

    /// The set of indices into @ref extract_infos that correspond to field slices that can end a
    /// CLOT, in descending order.
    std::vector<unsigned> can_end_indices_;

    /// Indicates which bits in the candidate are checksums, as defined in
    /// \ref clot_alloc_and_metric "CLOT allocator and metric" (README.md). The first
    /// element corresponds to the first bit of the first field slice in the candidate.
    bitvec checksum_bits;

    /// Indicates which bits in the candidate are modified, as defined in
    /// \ref clot_alloc_and_metric "CLOT allocator and metric" (README.md). The first
    /// element corresponds to the first bit of the first field slice in the candidate.
    bitvec modified_bits;

    /// Indicates which bits in the candidate are unused, as defined in
    /// \ref clot_alloc_and_metric "CLOT allocator and metric" (README.md). The first
    /// element corresponds to the first bit of the first field slice in the candidate.
    bitvec unused_bits;

    /// Indicates which bits in the candidate are read-only, as defined in
    /// \ref clot_alloc_and_metric "CLOT allocator and metric" (README.md). The first
    /// element corresponds to the first bit of the first field slice in the candidate.
    bitvec readonly_bits;

    static unsigned nextId;

 public:
    const unsigned id;

    /// The length of the candidate, in bits.
    unsigned size_bits;

    /// Indicates whether the candidate might immediately succeed an allocated CLOT with a 0-byte
    /// gap. When adjusting this candidate, if fields are removed from the beginning of the
    /// candidate, we need to make sure to remove at least Device::pardeSpec().byteInterClotGap()
    /// bytes.
    bool afterAllocatedClot;

    /// Indicates whether the candidate might immediately precede an allocated CLOT with a 0-byte
    /// gap. When adjusting this candidate, if fields are removed from the end of the candidate, we
    /// need to make sure to remove at least Device::pardeSpec().byteInterClotGap() bytes.
    bool beforeAllocatedClot;

    ClotCandidate(const ClotInfo& clotInfo,
                  const Pseudoheader* pseudoheader,
                  const std::vector<const FieldSliceExtractInfo*>& extract_infos,
                  bool afterAllocatedClot = false,
                  bool beforeAllocatedClot = false);

    /// The parser states containing this candidate's extracts.
    ordered_set<const IR::BFN::ParserState*> states() const;

    /// The pipe thread for the extracts in this candidate.
    gress_t thread() const;

    /// The state-relative offsets, in bits, of the first extract in the candidate.
    const ordered_map<const IR::BFN::ParserState*, unsigned>& state_bit_offsets() const;

    /// The bit-in-byte offset of the first extract in the candidate.
    unsigned bit_in_byte_offset() const;

    const std::vector<const FieldSliceExtractInfo*>& extracts() const;

    /// The indices into the vector returned by @a extracts, corresponding to fields that can
    /// start a CLOT, in ascending order.
    const std::vector<unsigned>& can_start_indices() const;

    /// The indices into the vector returned by @a extracts, corresponding to fields that can end
    /// a CLOT, in descending order.
    const std::vector<unsigned>& can_end_indices() const;

    /// Produces a map wherein the keys are all possible gap sizes, in bytes, between the end of
    /// this candidate and the start of another candidate when this candidate is parsed before the
    /// other candidate in the input packet. This key set corresponds to the GAPS function, as
    /// defined in \ref clot_alloc_and_metric "CLOT allocator and metric" (README.md).
    ///
    /// Each possible gap size is mapped to the set of parser states that realize that gap. Each
    /// set member is a pair, wherein the first component is the state containing this candidate,
    /// and the second component is the state containing @p other.
    const std::map<unsigned, StatePairSet> byte_gaps(const CollectParserInfo& parserInfo,
                                                     const ClotCandidate* other) const;

    /// Functionally updates this candidate with the given arguments by ORing them with the
    /// corresponding fields. If this results in no change, then this candidate is returned;
    /// otherwise, a new candidate is returned.
    const ClotCandidate* mark_adjacencies(bool afterAllocatedClot, bool beforeAllocatedClot) const;

    /// Lexicographic order according to (number of unused bits, number of read-only bits, id).
    bool operator<(const ClotCandidate& other) const;

    std::string print() const;
};

#endif /* EXTENSIONS_BF_P4C_PARDE_CLOT_CLOT_CANDIDATE_H_ */
