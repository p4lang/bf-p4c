#ifndef TOFINO_PHV_CONSTRAINTS_H_
#define TOFINO_PHV_CONSTRAINTS_H_
#include <map>
#include <set>
#include <cstdint>
#include "phv.h"
#include "solver_interface.h"
#include "ir/ir.h"
#include "lib/symbitmatrix.h"

class Constraints {
 public:
    Constraints() : unique_bit_id_counter_(0) { }
    // This functions modifies the internal data structures to express the
    // constraint that byte must be byte-aligned in a PHV container.
    void SetEqualByte(const PHV::Byte &byte);
    template<class T> void
    SetEqualByte(const T &begin, const T &end) {
        for (auto it = begin; it != end; std::advance(it, 1)) {
            SetEqualByte(*it); } }

    template<class T> void SetDeparsedHeader(const T &begin, const T &end, const gress_t gress) {
        deparsed_headers_.at(gress).insert(std::vector<PHV::Byte>(begin, end)); }
    void SetDeparsedPOV(const PHV::Bit &bit, const gress_t gress) {
        deparsed_pov_.at(gress).insert(bit); }
    template<class T> void SetDeparserBits(const T &begin, const T &end, const gress_t gress) {
        /* FIXME -- do we need a distinction between POV bits and other bits? */
        for (auto it = begin; it != end; ++it)
            deparsed_pov_.at(gress).insert(*it); }
    bool IsDeparsed(const PHV::Byte &byte) const;

    enum Equal {OFFSET, CONTAINER, MAU_GROUP, NUM_EQUALITIES};
    bool IsEqual(const PHV::Bit &bit1, const PHV::Bit &bit2, const Equal &e) const {
        return (equalities_[e].count(bit1) != 0) &&
               (equalities_[e].at(bit1).count(bit2) != 0); }
    std::set<PHV::Bit> GetEqual(const PHV::Bit &b, const Equal &e) const;
    template<class T>
    void SetEqual(const T &begin, const T &end, const Equal &eq) {
        auto it = (begin == end ? end : std::next(begin, 1));
        for (; it != end; std::advance(it, 1)) SetEqual_(*begin, *it, eq); }
    void SetOffset(const PHV::Bit &bit, const int &min, const int &max);
    void SetContiguousBits(const PHV::Bits &bits);
    // If b1 and b2 appear in an element of contiguous_bits_ object, this
    // function return a tuple of the distance between them and true. Otherwise,
    // it returns an invalid integer and false.
    std::pair<int, bool>
    GetDistance(const PHV::Bit &b1, const PHV::Bit &b2) const;
    // This function sets is_t_phv_ for bit to false.
    void SetNoTPhv(const PHV::Bit &bit);

    // These functions are used to specify the bits that are used at match keys
    // in TCAM and exact match tables.
    void SetExactMatchBits(const int &stage, const std::set<PHV::Bit> &bits);
    void SetTcamMatchBits(const int &stage, const std::set<PHV::Bit> &bits);

    // Sets/get conflict between the two bits.
    void SetContainerConflict(const PHV::Bit &b1, const PHV::Bit &b2);
    bool IsContainerConflict(const PHV::Bit &b1, const PHV::Bit &b2) const;
    void SetBitConflict(const PHV::Bit &b1, const PHV::Bit &b2);

    // Add a dst-src pair for the action function.
    void SetDstSrcPair(const cstring &af_name, const std::pair<PHV::Bit, PHV::Bit> &p);
    // The bits extracted in one path of the parse graph. This function sets a
    // bit-conflict between:
    // 1. All pairs of bits (b1, b2) such that b1 is in old_bits and b2 is in
    // new_bits.
    // 2. All pairs of bits(b1, b2) such that both b1 and b2 are in new_bits.
    // We could have had just 1 function parameter:
    // SetParseConflict(const PHV::Bits &all_bits)
    // and set bit-conflicts between every pair of bits in all_bits. But, this
    // would have been inefficient. We would end up setting conflicts between the
    // same pair of bits multiple times if they appeared in the different paths
    // together.
    void SetParseConflict(const PHV::Bits &old_bits, const PHV::Bits &new_bits);
    void SetConstraints(SolverInterface &solver);
    template<class T> void SetConstraints(const Equal &e, T set_equal, std::set<PHV::Bit> bits);

 private:
    // This type is used to identify a bit in the internal data structures of
    // this class.
    typedef uint16_t BitId;
    void SetEqual_(const PHV::Bit &bit1, const PHV::Bit &bit2, const Equal &eq);
    // This function return the byte containing b.
    PHV::Byte GetByte(const PHV::Bit &b) const;
    void SetMatchBits(const std::set<PHV::Bit> &bits, std::vector<PHV::Bit> *v);
    // Data structures to store constraints.
    // Each map in the array stores an equality constraint (equality of MAU
    // groups, containers or offsets inside a container). For example, if
    // equalities_[Equal::OFFSET] has an entry ipv4[0] : std::set({inner_ipv4[0],
    // ipv6[0]}), then it means that the first bit of ipv4, inner_ipv4 and ipv6
    // needs to be allocated at the same offset inside a container. However, they
    // need not be allocated to the same container.
    std::map<PHV::Bit, std::set<PHV::Bit>> equalities_[NUM_EQUALITIES];
    std::set<PHV::Byte> byte_equalities_;
    // The 2 std::map objects below store constraints on bits. A bit can contain
    // an entry in either of the 2 maps but not both.
    // This is a bit-to-offset range map. The bit must be allocated an offset
    // within the range (inclusive).
    std::map<PHV::Bit, std::pair<int, int>> bit_offset_range_;
    // The domain of possible offset that a bit can be allocated. The values must
    // be stored in sorted order in the vector.
    std::map<PHV::Bit, std::vector<int>> bit_offset_domain_;
    // The bits in every PHV::Bits object must be assigned to contiguous offsets.
    // However, they need not be assigned to the same PHV container.
    std::list<PHV::Bits> contiguous_bits_;
    // Returns true if all the bits in pbits must be allocated to contiguous bits
    // in a PHV container. False otherwise.
    bool IsContiguous(const PHV::Bits &pbits) const;
    // Each element in this map stores a set of destination-source pairs of an
    // action. This map is used for the single-source PHV container constraint.
    // The key is the name of the ActionFunction.
    std::map<cstring, std::set<std::pair<PHV::Bit, PHV::Bit>>> dst_src_pairs_;
    // An array with 2 elements, one for ingress and one for egress. We need the
    // thread-specific mapping because we need to add the deparser-group
    // constraint between the bytes of two headers that belong to different
    // threads.  We also need the POV bits for the headers.
    std::array<std::set<std::vector<PHV::Byte>>, 2> deparsed_headers_;
    std::array<std::set<PHV::Bit>, 2> deparsed_pov_;
    // A vector of flags to indicate if a bit can be assigned to T-PHV. This
    // vector is indexed by BitId.
    std::vector<bool> is_t_phv_;
    // TODO: Change these to use BitId instead of PHV::Bit to save memory.
    // The std::vector<PHV::Bit> is a vector of bits extracted by the exact match
    // and TCAM xbar in each stage. Each vector does not contain any duplicates
    // and does not even contain two bits that must appear in the same PHV byte.
    // For example, if ipv4.srcAddr is used as a key in a match lookup, only 4
    // bits (one from each byte) will appear in the std::vector<PHV::Bit>.
    std::vector<std::vector<PHV::Bit>> exact_match_bits_;
    std::vector<std::vector<PHV::Bit>> tcam_match_bits_;
    // Conflict matrices: A "true" indicates the the corresponding bits cannot be
    // allocated to the same PHV container/bit. The inner and outer vectors in
    // both conflict matrices are indexed by BitId. Example: If
    // container_conflicts_[i][j] is true, bits_[i] and bits_[j] cannot be
    // allocated to the same PHV container.
    // Two bits can have container conflicts if any of the following conditions
    // are true:
    // 1.They appear in different headers which are deparsed and may appear in
    // the same packet.
    // 2. They are written to (using modify_field) in the same action from two
    // bits which have a container conflict. See case 2 in
    // source_container_constraint.cpp.
    // 3. They appear in a header that is deparsed but they are more than 32b
    // apart in the header.
    // 4. They are written from actions in different tables in the same stage and
    // these tables may match on the same packet.
    SymBitMatrix container_conflicts_;
    // Two bits can have bit conflicts if any of the following conditions
    // are true:
    // 1. They are alive in the same stage in the MAU and can be accessed by the
    // same packet and may carry different data.
    // 2. They appear in headers that are reachable in the parse graph.
    // TODO: Data flow analysis: If two fields are active at the same time but
    // are guaranteed to carry the same data, we should not add a bit conflict
    // between them. Example: When we do set_metadata(ipv4.version, m.v); in the
    // parser, we should not add a conflict between the corresponding bits of
    // ipv4.version bits and m.v even though they are alive at the same time in
    // the header and MAU stages. Only if we modify either field in the pipeline,
    // we should add a bit-conflict. If we don't add a conflict between them and
    // the solver overlays the 2 bits, a subsequent pass should remove the
    // redundant "set_metadata" primitive from the IR.
    SymBitMatrix bit_conflicts_;
    // Helper functions to generate/retrieve a unique ID for a bit.
    BitId unique_bit_id(const PHV::Bit &bit);
    BitId unique_bit_id(const PHV::Bit &bit) const;
    BitId unique_bit_id_counter_;
    std::map<PHV::Bit, BitId> uniq_bit_ids_;
    std::vector<PHV::Bit> bits_;
    void UnionEqualities(const Equal &a, const Equal &b);
};
template<> void
Constraints::SetEqual<PHV::Bit>(const PHV::Bit &bit1, const PHV::Bit &bit2,
                                const Equal &eq);

inline std::ostream &operator<<(std::ostream &out, Constraints::Equal eq) {
    switch (eq) {
    case Constraints::Equal::OFFSET: return out << "Equal::OFFSET";
    case Constraints::Equal::CONTAINER: return out << "Equal::CONTAINER";
    case Constraints::Equal::MAU_GROUP: return out << "Equal::MAU_GROUP";
    case Constraints::Equal::NUM_EQUALITIES: return out << "Equal::NUM_EQUALITIES";
    default: return out << "<invalid Equal>"; } }

#endif /* TOFINO_PHV_CONSTRAINTS_H_ */
