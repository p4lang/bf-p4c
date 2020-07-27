#ifndef EXTENSIONS_BF_P4C_PARDE_CLOT_CLOT_CANDIDATE_H_
#define EXTENSIONS_BF_P4C_PARDE_CLOT_CLOT_CANDIDATE_H_

#include "bf-p4c/lib/cmp.h"
#include "clot_info.h"
#include "pseudoheader.h"

class FieldSliceExtractInfo;

class ClotCandidate : public LiftLess<ClotCandidate> {
 public:
    const Pseudoheader* pseudoheader;


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
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU. The first
    /// element corresponds to the first bit of the first field slice in the candidate.
    bitvec checksum_bits;

    /// Indicates which bits in the candidate are modified, as defined in
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU. The first
    /// element corresponds to the first bit of the first field slice in the candidate.
    bitvec modified_bits;

    /// Indicates which bits in the candidate are unused, as defined in
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU. The first
    /// element corresponds to the first bit of the first field slice in the candidate.
    bitvec unused_bits;

    /// Indicates which bits in the candidate are read-only, as defined in
    /// https://docs.google.com/document/d/1dWLuXoxrdk6ddQDczyDMksO8L_IToOm21QgIjHaDWXU. The first
    /// element corresponds to the first bit of the first field slice in the candidate.
    bitvec readonly_bits;

    static unsigned nextId;

 public:
    const unsigned id;

    /// The length of the candidate, in bits.
    unsigned size_bits;

    ClotCandidate(const ClotInfo& clotInfo,
                  const Pseudoheader* pseudoheader,
                  const std::vector<const FieldSliceExtractInfo*>& extract_infos);

    /// The parser states containing this candidate's extracts.
    ordered_set<const IR::BFN::ParserState*> states() const;

    /// The pipe thread for the extracts in this candidate.
    gress_t thread() const;

    /// The state-relative offsets, in bits, of the first extract in the candidate.
    const ordered_map<const IR::BFN::ParserState*, unsigned>& state_bit_offsets() const;

    /// The bit-in-byte offset of the first extract in the candidate.
    unsigned bit_in_byte_offset() const;

    const std::vector<const FieldSliceExtractInfo*>& extracts() const;

    /// The indices into the vector returned by @ref extracts, corresponding to fields that can
    /// start a CLOT, in ascending order.
    const std::vector<unsigned>& can_start_indices() const;

    /// The indices into the vector returned by @ref extracts, corresponding to fields that can end
    /// a CLOT, in descending order.
    const std::vector<unsigned>& can_end_indices() const;

    /// Lexicographic order according to (number of unused bits, number of read-only bits, id).
    bool operator<(const ClotCandidate& other) const;

    std::string print() const;
};

#endif /* EXTENSIONS_BF_P4C_PARDE_CLOT_CLOT_CANDIDATE_H_ */
