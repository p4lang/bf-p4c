#ifndef EXTENSIONS_BF_P4C_PARDE_CLOT_H_
#define EXTENSIONS_BF_P4C_PARDE_CLOT_H_

#include <vector>
#include <map>
#include <set>

#include "bf-p4c/ir/gress.h"
#include "lib/exceptions.h"

namespace IR {
namespace BFN {
class ParserState;
} }

namespace PHV {
class Field;
}

namespace IR {
namespace BFN {
class ParserState;
}
}

class cstring;
class JSONGenerator;
class JSONLoader;
class PhvInfo;

class Clot {
    friend class GreedyClotAllocator;

 public:
    /// JSON deserialization constructor
    Clot() : tag(0), gress(INGRESS) {}

    explicit Clot(gress_t gress) : tag(tagCnt[gress]++), gress(gress) {
        BUG_CHECK(gress != GHOST, "Cannot assign CLOTs to ghost gress.");
    }

    explicit Clot(cstring);

    cstring toString() const;

    bool operator==(const Clot& c) const {
        return tag == c.tag && gress == c.gress;
    }

    bool operator!=(const Clot& c) const {
        return !(*this == c);
    }

    /// JSON serialization/deserialization.
    void toJSON(JSONGenerator& json) const;
    static Clot fromJSON(JSONLoader& json);

    /// Identifies the hardware CLOT associated with this object.
    unsigned tag;

    /// The gress to which this CLOT is assigned.
    gress_t gress;

    unsigned start = 0;  // start byte offset, relative to the parser state

    /// Returns the bit offset of a field within this CLOT.
    unsigned bit_offset(const PHV::Field* f) const;

    /// Returns the byte offset of a field within this CLOT.
    unsigned byte_offset(const PHV::Field* f) const;

    /// @return true when @arg f is a PHV-allocated field in this CLOT.
    bool is_phv_field(const PHV::Field* f) const;

    /// @return true when @arg f is a checksum field in this CLOT.
    bool is_csum_field(const PHV::Field* f) const;

    bool has_field(const PHV::Field* f) const;

    /// Trims this CLOT so it only contains a subsequence of fields. @arg start_idx and @arg
    /// end_idx are indices into @ref all_fields, specifying the closed interval of fields that
    /// should be kept. If @arg start_idx > @arg end_idx, then all fields will be removed from this
    /// CLOT.
    void crop(int start_idx, int end_idx);

 private:
    enum FieldKind {
        // Designates a modified field.
        MODIFIED,

        // Designates an unmodified field with a PHV allocation.
        READONLY,

        // Designates a field that is replaced with a checksum when deparsed.
        CHECKSUM,

        UNUSED
    };

    /// Adds a field to this CLOT.
    ///
    /// @arg offset - the field's bit offset from the beginning of this CLOT.
    void add_field(FieldKind kind,
                   const PHV::Field* field,
                   unsigned offset);

    /// Maps the fields in this CLOT to their bit offset from the beginning of this CLOT.
    std::map<const PHV::Field*, unsigned> field_offsets;

    /// All fields in this CLOT, in the order in which they were added.
    std::vector<const PHV::Field*> all_fields_;

    /// All fields in this CLOT that also have a PHV allocation. This consists of all modified and
    /// read-only fields in this CLOT.
    std::set<const PHV::Field*> phv_fields_;

    /// All modified fields in this CLOT..
    std::set<const PHV::Field*> phv_modified_fields_;

    /// Fields that need to be replaced by a checksum when deparsed.
    std::set<const PHV::Field*> csum_fields_;

 public:
    /// Returns all fields covered by this CLOT.
    const std::vector<const PHV::Field*>& all_fields() const {
        return all_fields_;
    }

    /// Fields in this CLOT that also have a PHV allocation.
    const std::set<const PHV::Field*>& phv_fields() const {
        return phv_fields_;
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
