#ifndef BF_P4C_PARDE_ADD_METADATA_POV_H_
#define BF_P4C_PARDE_ADD_METADATA_POV_H_

#include "ir/ir.h"
#include "bf-p4c/phv/phv_fields.h"


/**@brief Create POV bits for output metadata (JBAY / Cloudbreak / Flatrock)
 *
 * JBay / CloudBreak requires POV bits to control output metadata as implicit
 * PHV valid bits are gone.  We create a single POV bit for each metadata in use
 * and set the bit whenever the metadata is set.
 *
 * Flatrock requires POV bits for a subset of fields.
 */

class AddMetadataPOV : public Transform {
    const PhvInfo &phv;
    const IR::BFN::Deparser *dp = nullptr;

#if HAVE_FLATROCK
    static std::map<cstring, std::set<cstring>> flatrock_dprsr_param_with_pov;

    bool is_deparser_parameter_with_pov(const IR::BFN::DeparserParameter *param);
#endif /* HAVE_FLATROCK */

    bool equiv(const IR::Expression *a, const IR::Expression *b);
    static IR::MAU::Primitive *create_pov_write(const IR::Expression *povBit, bool validate);
    IR::Node *insert_deparser_param_pov_write(const IR::MAU::Primitive *p, bool validate);
    IR::Node *insert_deparser_digest_pov_write(const IR::MAU::Primitive *p, bool validate);

    IR::BFN::Pipe *preorder(IR::BFN::Pipe *pipe) override;

    IR::BFN::DeparserParameter *postorder(IR::BFN::DeparserParameter *param) override;
    IR::BFN::Digest *postorder(IR::BFN::Digest *digest) override;
    IR::Node *postorder(IR::MAU::Primitive *p) override;
    IR::Node *postorder(IR::BFN::Extract *e) override;

 public:
    explicit AddMetadataPOV(PhvInfo &p) : phv(p) {}
};

#endif /* BF_P4C_PARDE_ADD_METADATA_POV_H_ */
