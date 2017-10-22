#ifndef BF_P4C_PARDE_ADD_PARDE_METADATA_H_
#define BF_P4C_PARDE_ADD_PARDE_METADATA_H_

#include "parde_visitor.h"

/**@brief Extend parsers to extract standard metadata.
 *
 * "Standard metadata" refers to hardware-specific metadata, such as the
 * ingress port or egress spec.  Tofino prepends packets with metadata, which
 * needs to be extracted by the parser before applying the user-supplied parser.
 */

class AddMetadataShims : public PardeModifier {
 public:
    explicit AddMetadataShims(const IR::BFN::Pipe* pipe, bool useTna = false)
            : pipe(pipe), useTna(useTna) { CHECK_NULL(pipe); }

 private:
    bool preorder(IR::BFN::Parser *) override;
    bool preorder(IR::BFN::Deparser *) override;

    void addIngressMetadata(IR::BFN::Parser *d);
    void addEgressMetadata(IR::BFN::Parser *d);

    void addDeparserIntrinsic(IR::BFN::Deparser *d, const IR::HeaderOrMetadata *meta,
                          cstring field, cstring intrinsic);
    void addIngressMetadata(IR::BFN::Deparser *d);
    void addEgressMetadata(IR::BFN::Deparser *d);

    const IR::BFN::Pipe* pipe;
    const bool useTna;
};

#endif /* BF_P4C_PARDE_ADD_PARDE_METADATA_H_ */
