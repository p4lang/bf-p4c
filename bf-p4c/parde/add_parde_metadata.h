#ifndef BF_P4C_PARDE_ADD_PARDE_METADATA_H_
#define BF_P4C_PARDE_ADD_PARDE_METADATA_H_

#include "parde_visitor.h"

/**@brief Extend parsers to extract standard metadata.
 *
 * "Standard metadata" refers to hardware-specific metadata, such as the
 * ingress port or egress spec.  Tofino prepends packets with metadata, which
 * needs to be extracted by the parser before applying the user-supplied parser.
 */

class AddParserMetadata : public ParserModifier {
 public:
    explicit AddParserMetadata(const IR::BFN::Pipe* pipe, bool isV1)
            : pipe(pipe), isV1(isV1) { CHECK_NULL(pipe); }

 private:
    bool preorder(IR::BFN::Parser *) override;

    void addIngressMetadata(IR::BFN::Parser *d);
    void addEgressMetadata(IR::BFN::Parser *d);

    const IR::BFN::Pipe* pipe;
    bool isV1;
};

class AddDeparserMetadata : public DeparserModifier {
 public:
    explicit AddDeparserMetadata(const IR::BFN::Pipe* pipe)
        : pipe(pipe) { CHECK_NULL(pipe); }

    bool preorder(IR::BFN::Deparser *) override;

    void addIngressMetadata(IR::BFN::Deparser *d);
    void addEgressMetadata(IR::BFN::Deparser *d);

    const IR::BFN::Pipe* pipe;
};

#endif /* BF_P4C_PARDE_ADD_PARDE_METADATA_H_ */
