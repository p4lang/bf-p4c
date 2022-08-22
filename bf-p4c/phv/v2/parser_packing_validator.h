#ifndef BF_P4C_PHV_V2_PARSER_PACKING_VALIDATOR_H_
#define BF_P4C_PHV_V2_PARSER_PACKING_VALIDATOR_H_

#include "ir/ir.h"

#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/parde/parser_info.h"
#include "bf-p4c/phv/parser_packing_validator_interface.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "bf-p4c/phv/v2/utils_v2.h"

namespace PHV {
namespace v2 {

/// what we have done wrong:
/// only check against candidate and allocated: this is because we assume that slice lists
/// make sure that the packing is okay because they are very likely coming out from a header.
/// But, it is not true for
/// (1) bridged metadata, they are metadata and we packed them.
/// (2) fancy usage of header fields.
/// (3) result came from co-packer or table key optimization packing.
/// (4) pa_byte_pack.
class ParserPackingValidator : public ParserPackingValidatorInterface {
 private:
    using StateExtract = std::pair<const IR::BFN::ParserState*, const IR::BFN::Extract*>;
    using StateExtractMap =
        ordered_map<const IR::BFN::ParserState*, std::vector<const IR::BFN::Extract*>>;
    const PhvInfo& phv_i;
    const MapFieldToParserStates& parser_i;
    const CollectParserInfo& parser_info_i;
    const FieldDefUse& defuse_i;
    const PragmaNoInit& pa_no_init_i;

    /// @returns all extracts to @p f, grouped by states.
    StateExtractMap get_extracts(const Field* f) const;

    /// @returns true if the field needs to be the default value when it left parser.
    /// The default value is zero and the container validity bit (in Tofino) is zero.
    bool parser_zero_init(const Field* f) const {
        return (defuse_i.hasUninitializedRead(f->id) && !pa_no_init_i.getFields().count(f));
    }

    /// @returns true if it is okay to write random bits to @p in parser.
    bool allow_clobber(const Field* f) const;

    /// @returns an error if @p state_extract will clobber value of other_fs in parser.
    const AllocError* will_buf_extract_clobber_the_other(
            const FieldSlice& fs, const StateExtract& state_extract, const int cont_idx,
            const FieldSlice& other_fs, const StateExtractMap& other_extracts,
            const int other_cont_idx, const boost::optional<Container>& c) const;

    /// @returns an error if there is an extract from a that will clobber b's bits.
    const AllocError* will_a_extracts_clobber_b(const FieldSliceStart& a,
                                                const FieldSliceStart& b,
                                                const boost::optional<Container>& c) const;

 public:
    explicit ParserPackingValidator(const PhvInfo& phv,
                                    const MapFieldToParserStates& parser,
                                    const CollectParserInfo& parser_info,
                                    const FieldDefUse& defuse,
                                    const PragmaNoInit& pa_no_init)
        : phv_i(phv),
          parser_i(parser),
          parser_info_i(parser_info),
          defuse_i(defuse),
          pa_no_init_i(pa_no_init) {}

    /// @returns an error if we cannot allocated @p a and @p b in a container.
    /// @p c is optional for 32-bit container half-word extract optimization.
    const AllocError* can_pack(const FieldSliceStart& a,
                               const FieldSliceStart& b,
                               const boost::optional<Container>& c) const;

    /// @returns an error if we allocated slices in the format of @p alloc.
    /// @p c is optional for 32-bit container half-word extract optimization.
    const AllocError* can_pack(const FieldSliceAllocStartMap& alloc,
                               const boost::optional<Container>& c) const override;
};

}  // namespace v2
}  // namespace PHV

#endif /* BF_P4C_PHV_V2_PARSER_PACKING_VALIDATOR_H_ */
