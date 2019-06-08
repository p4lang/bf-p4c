#ifndef EXTENSIONS_BF_P4C_PARDE_CLOT_H_
#define EXTENSIONS_BF_P4C_PARDE_CLOT_H_

#include <vector>
#include <map>
#include <set>

#include "bf-p4c/ir/gress.h"
#include "bf-p4c/lib/cmp.h"
#include "lib/exceptions.h"

namespace IR {
namespace BFN {
class ParserState;
}
}

namespace PHV {
class Field;
class FieldSlice;
}

class cstring;
class JSONGenerator;
class JSONLoader;
class PhvInfo;

class Clot : public LiftCompare<Clot> {
    friend class ClotInfo;
    friend class GreedyClotAllocator;

 public:
    /// JSON deserialization constructor
    Clot() : tag(0), gress(INGRESS) {}

    explicit Clot(gress_t gress) : tag(tagCnt[gress]++), gress(gress) {
        BUG_CHECK(gress != GHOST, "Cannot assign CLOTs to ghost gress.");
    }

    explicit Clot(cstring);

    cstring toString() const;

    /// Equality based on gress and tag.
    bool operator==(const Clot& c) const {
        return tag == c.tag && gress == c.gress;
    }

    /// Lexicographic ordering according to (gress, tag).
    bool operator<(const Clot& c) const {
        if (gress != c.gress) return gress < c.gress;
        return tag < c.tag;
    }

    /// JSON serialization/deserialization.
    void toJSON(JSONGenerator& json) const;
    static Clot fromJSON(JSONLoader& json);

    /// Identifies the hardware CLOT associated with this object.
    unsigned tag;

    /// The gress to which this CLOT is assigned.
    gress_t gress;

    unsigned length_in_byte() const;

    /// Returns the bit offset of a field slice within this CLOT. An error occurs if the CLOT does
    /// not contain the exact field slice (i.e., if the given field slice is not completely covered
    /// by this CLOT, or if the CLOT contains a larger slice of the field).
    unsigned bit_offset(const PHV::FieldSlice* slice) const;

    /// Returns the byte offset of a field slice within this CLOT. An error occurs if the CLOT does
    /// not contain the exact field slice (i.e., if the given field slice is not completely covered
    /// by this CLOT, or if the CLOT contains a larger slice of the field).
    unsigned byte_offset(const PHV::FieldSlice* slice) const;

    /// @return true when @arg f is a PHV-allocated field, and this CLOT has (a slice of) @arg f.
    bool is_phv_field(const PHV::Field* f) const;

    /// @return true when @arg f is a checksum field, and this CLOT has (a slice of) @arg f.
    bool is_csum_field(const PHV::Field* f) const;

    /// @return true when this CLOT has the exact @arg slice.
    bool has_slice(const PHV::FieldSlice* slice) const;

    /// @return true when the first slice in this CLOT is part of the given field @arg f.
    bool is_first_field_in_clot(const PHV::Field* f) const;

 private:
    void set_slices(const std::vector<const PHV::FieldSlice*> slices);

    enum FieldKind {
        // Designates a modified field.
        MODIFIED,

        // Designates an unmodified field with a PHV allocation.
        READONLY,

        // Designates a field that is replaced with a checksum when deparsed.
        CHECKSUM,

        UNUSED
    };

    /// Adds a field slice to this CLOT.
    void add_slice(FieldKind kind, const PHV::FieldSlice* slice);

    /// All field slices in this CLOT, in the order in which they were added.
    std::vector<const PHV::FieldSlice*> all_slices_;

    /// All fields that have slices in this CLOT, mapped to their corresponding slice.
    std::map<const PHV::Field*, const PHV::FieldSlice*> fields_to_slices_;

    /// All fields that have slices in this CLOT and also have a PHV allocation. This consists of
    /// all modified and read-only fields that have slices in this CLOT.
    std::set<const PHV::Field*> phv_fields_;

    /// Fields that need to be replaced by a checksum when deparsed.
    std::set<const PHV::Field*> csum_fields_;

 public:
    /// Returns all field slices covered by this CLOT.
    const std::vector<const PHV::FieldSlice*>& all_slices() const {
        return all_slices_;
    }

    /// Returns all fields that have slices in this CLOT, mapped to their corresponding slice.
    const std::map<const PHV::Field*, const PHV::FieldSlice*>& fields_to_slices() const {
        return fields_to_slices_;
    }

    /// Returns all fields that need to be replaced by a checksum when deparsed.
    const std::set<const PHV::Field*>& csum_fields() const {
        return csum_fields_;
    }

    std::map<const PHV::Field*, unsigned> csum_field_to_csum_id;

    static std::map<gress_t, int> tagCnt;
};

std::ostream& operator<<(std::ostream& out, const Clot c);
JSONGenerator& operator<<(JSONGenerator& out, const Clot c);

#endif /* EXTENSIONS_BF_P4C_PARDE_CLOT_H_ */
