#ifndef EXTENSIONS_BF_P4C_PARDE_CLOT_H_
#define EXTENSIONS_BF_P4C_PARDE_CLOT_H_

#include <vector>
#include <map>

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

class Clot {
 public:
    Clot() { tag = tagCnt++; }
    explicit Clot(cstring);

    cstring toString() const;

    bool operator==(const Clot& c) const {
        return tag == c.tag;
    }

    /// JSON serialization/deserialization.
    void toJSON(JSONGenerator& json) const;
    static Clot fromJSON(JSONLoader& json);

    enum FieldKind {
        // Designates a field that is replaced with PHVs when deparsed.
        PHV,

        // Designates a field that is replaced with a checksum when deparsed.
        CHECKSUM,

        // Designates a field that not replaced when deparsed.
        OTHER
    };

    unsigned tag = 0;  // 0 = invalid

    unsigned start = 0;  // start byte offset in the packet

    /// Returns the bit offset of a field within this CLOT.
    unsigned bit_offset(const PHV::Field* f) const;

    /// Returns the byte offset of a field within this CLOT.
    unsigned byte_offset(const PHV::Field* f) const;

    /// Determines whether @arg f is a PHV-allocated field in this CLOT.
    bool is_phv_field(const PHV::Field* f) const;

    /// Determines whether @arg f is a checksum field in this CLOT.
    bool is_csum_field(const PHV::Field* f) const;

    bool has_field(const PHV::Field* f) const;

    /// Adds a field to this CLOT.
    ///
    /// @arg offset - the field's bit offset from the beginning of this CLOT.
    void add_field(const IR::BFN::ParserState* state,
                   FieldKind kind,
                   const PHV::Field* field,
                   unsigned offset);

 private:
    /// Maps the fields in this CLOT to their bit offset from the beginning of this CLOT.
    std::map<const PHV::Field*, unsigned> field_offsets;

    /// All fields in this CLOT, in the order in which they were added.
    std::vector<const PHV::Field*> all_fields_;

    /// The fields that need to be replaced by PHVs when deparsed.
    std::vector<const PHV::Field*> phv_fields_;

    /// The fields that need to be replaced by a checksum when deparsed.
    std::vector<const PHV::Field*> csum_fields_;

    /// The parser states for which this CLOT was allocated, mapped to the corresponding fields
    /// allocated to this CLOT, in the order in which the fields were added.
    std::map<const IR::BFN::ParserState*, std::vector<const PHV::Field*>> parser_state_to_fields_;

 public:
    /// Returns all fields covered by this CLOT.
    const std::vector<const PHV::Field*> all_fields() const {
        return all_fields_;
    }

    /// Returns all fields that need to be replaced by PHVs when deparsed.
    const std::vector<const PHV::Field*> phv_fields() const {
        return phv_fields_;
    }

    /// Returns all fields that need to be replaced by a checksum when deparsed.
    const std::vector<const PHV::Field*> csum_fields() const {
        return csum_fields_;
    }

    /// Returns all parser states for which this CLOT was allocated, mapped to the corresponding
    /// fields allocated to this CLOT.
    const std::map<const IR::BFN::ParserState*, std::vector<const PHV::Field*>>
    parser_state_to_fields() const {
        return parser_state_to_fields_;
    }

    std::map<const PHV::Field*, unsigned> csum_field_to_csum_id;

    static int tagCnt;
};

std::ostream& operator<<(std::ostream& out, const Clot c);
JSONGenerator& operator<<(JSONGenerator& out, const Clot c);

#endif /* EXTENSIONS_BF_P4C_PARDE_CLOT_H_ */
