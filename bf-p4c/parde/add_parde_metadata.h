#ifndef _TOFINO_PARDE_ADD_PARDE_METADATA_H_
#define _TOFINO_PARDE_ADD_PARDE_METADATA_H_

#include "parde_visitor.h"

/**@brief Extend parsers to extract standard metadata.
 *
 * "Standard metadata" refers to hardware-specific metadata, such as the
 * ingress port or egress spec.  Tofino prepends packets with metadata, which
 * needs to be extracted by the parser before applying the user-supplied parser.
 */

class AddMetadataShims : public PardeModifier {
 public:
    explicit AddMetadataShims(const IR::Tofino::Pipe* pipe) : pipe(pipe)
    { CHECK_NULL(pipe); }

 private:
    bool preorder(IR::Tofino::Parser *) override;
    bool preorder(IR::Tofino::Deparser *) override;

    const IR::Tofino::Pipe* pipe;
};

#endif /* _TOFINO_PARDE_ADD_PARDE_METADATA_H_ */
