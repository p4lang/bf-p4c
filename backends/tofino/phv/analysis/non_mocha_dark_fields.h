#ifndef P4C_EXTENSIONS_BF_P4C_PHV_ANALYSIS_NON_MOCHA_DARK_FIELDS_H_
#define P4C_EXTENSIONS_BF_P4C_PHV_ANALYSIS_NON_MOCHA_DARK_FIELDS_H_

#include "ir/ir.h"

#include "backends/tofino/common/field_defuse.h"
#include "backends/tofino/mau/action_analysis.h"
#include "backends/tofino/phv/phv.h"
#include "backends/tofino/phv/phv_fields.h"
#include "backends/tofino/phv/pragma/phv_pragmas.h"

class NonMochaDarkFields : public Inspector {
 public:
    using FieldMap = std::map<const int, std::map<const IR::MAU::Table *, PHV::FieldUse>>;

 private:
    static const PHV::FieldUse READ;
    static const PHV::FieldUse WRITE;

    const PhvInfo &phv;
    const PhvUse &uses;
    const FieldDefUse &defuse;
    const ReductionOrInfo &red_info;

    /// List of fields that are marked as pa_no_init, which means that we assume the live range of
    /// these fields is from the first use of it to the last use.
    const ordered_set<const PHV::Field *> &noInitFields;
    /// List of fields that are marked as not parsed.
    const ordered_set<const PHV::Field *> &notParsedFields;
    /// List of fields that are marked as not deparsed.
    const ordered_set<const PHV::Field *> &notDeparsedFields;

    FieldMap nonDark;
    FieldMap nonMocha;

    profile_t init_apply(const IR::Node *root) override;
    bool preorder(const IR::MAU::Action *act) override;
    void end_apply() override;

 public:
    NonMochaDarkFields(const PhvInfo &phv, const PhvUse &uses, const FieldDefUse &defuse,
                       const ReductionOrInfo &ri, const PHV::Pragmas &pragmas)
        : phv(phv),
          uses(uses),
          defuse(defuse),
          red_info(ri),
          noInitFields(pragmas.pa_no_init().getFields()),
          notParsedFields(pragmas.pa_deparser_zero().getNotDeparsedFields()),
          notDeparsedFields(pragmas.pa_deparser_zero().getNotDeparsedFields()) {}

    PHV::FieldUse isNotMocha(const PHV::Field *field, const IR::MAU::Table *tbl = nullptr) const;

    PHV::FieldUse isNotDark(const PHV::Field *field, const IR::MAU::Table *tbl = nullptr) const;

    const FieldMap &getNonMocha() const { return nonMocha; }

    const FieldMap &getNonDark() const { return nonDark; }
};

#endif /* P4C_EXTENSIONS_BF_P4C_PHV_ANALYSIS_NON_MOCHA_DARK_FIELDS_H_ */
