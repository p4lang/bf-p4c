#ifndef BF_P4C_PARDE_ADD_PARDE_METADATA_H_
#define BF_P4C_PARDE_ADD_PARDE_METADATA_H_

#include "parde_visitor.h"

/**
 * @ingroup parde
 *
 * @brief Extend parsers to extract standard metadata.
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

    void addTofinoIngressParserEntryPoint(IR::BFN::Parser *);
    void addTofinoEgressParserEntryPoint(IR::BFN::Parser *);

#if HAVE_FLATROCK
    void addFlatrockIngressParserEntryPoint(IR::BFN::Parser *);
#endif  // HAVE_FLATROCK

    const IR::BFN::Pipe* pipe;
    bool isV1;
};

/**
 * @ingroup parde
 *
 * @brief Add deparser parameters for standard metadata.
 *
 * Add deparser parameters for "standard metadata" required by the hardware. An example is the
 * egress port information required required by TM: this is a parameter that the deparser needs to
 * provide.
 *
 * The ArchSpec for the current device defines the metadata parameters to add.
 */
class AddDeparserMetadata : public DeparserModifier {
 public:
    explicit AddDeparserMetadata(const IR::BFN::Pipe* pipe)
        : pipe(pipe) { CHECK_NULL(pipe); }

    /// Process the deparser instances to add parameters
    bool preorder(IR::BFN::Deparser *) override;

    /// Add ingress deparser parameters
    void addIngressMetadata(IR::BFN::Deparser *d);

    // Add egress deparser parameters
    void addEgressMetadata(IR::BFN::Deparser *d);

    const IR::BFN::Pipe* pipe;
};

#endif /* BF_P4C_PARDE_ADD_PARDE_METADATA_H_ */
