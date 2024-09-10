#ifndef EXTENSIONS_BF_P4C_ARCH_ARCH_SPEC_H_
#define EXTENSIONS_BF_P4C_ARCH_ARCH_SPEC_H_

#include "ir/ir.h"
#include "backends/tofino/ir/gress.h"

struct IntrinsicField {
 public:
    cstring name;
    cstring asm_name;
    explicit IntrinsicField(cstring n) : name(n), asm_name(n) { }
    IntrinsicField(cstring n, cstring an) : name(n), asm_name(an) { }
};

struct IntrinsicParam {
 public:
    cstring type;
    cstring name;
    IntrinsicParam(cstring t, cstring n) : type(t), name(n) { }
};

/**
 * This class is the architecture model for tofino devices.
 * TOF5-DOC: It also applies to Flatrock devices.
 * P4-16 architecture file exposes the user-configurable CSRs as
 * intrinsic metadata to P4 programmers. Different generation of
 * devies may have different set of CSRs, which is encapsulated in
 * this class.
 */
class ArchSpec {
 protected:
    std::vector<IntrinsicField> intrinsic_metadata[GRESS_T_COUNT];
    std::vector<IntrinsicField> intrinsic_metadata_for_tm[GRESS_T_COUNT];
    std::vector<IntrinsicField> intrinsic_metadata_from_parser[GRESS_T_COUNT];
    std::vector<IntrinsicField> intrinsic_metadata_for_deparser[GRESS_T_COUNT];
    std::vector<IntrinsicField> intrinsic_metadata_for_output_port[GRESS_T_COUNT];

    std::vector<IntrinsicParam> parser_intrinsic_types[GRESS_T_COUNT];
    std::vector<IntrinsicParam> mauppu_intrinsic_types[GRESS_T_COUNT];
    std::vector<IntrinsicParam> deparser_intrinsic_types[GRESS_T_COUNT];

    int deparser_intrinsic_metadata_for_deparser_param_index = -1;

 public:
    enum ArchType_t { TNA, T2NA
#if HAVE_CLOUDBREAK
        , T3NA
#endif
#if HAVE_FLATROCK
        , T5NA
#endif
    };

    ArchSpec();

    std::vector<IntrinsicField> getIngressIntrinsicMetadata() const {
        return intrinsic_metadata[INGRESS];
    }

    std::vector<IntrinsicField> getIngressInstrinicMetadataFromParser() const {
        return intrinsic_metadata_from_parser[INGRESS];
    }

    std::vector<IntrinsicField> getIngressInstrinicMetadataForTM() const {
        return intrinsic_metadata_for_tm[INGRESS];
    }

    std::vector<IntrinsicField> getIngressInstrinicMetadataForDeparser() const {
        return intrinsic_metadata_for_deparser[INGRESS];
    }

    std::vector<IntrinsicField> getEgressIntrinsicMetadata() const {
        return intrinsic_metadata[EGRESS];
    }

    std::vector<IntrinsicField> getEgressIntrinsicMetadataFromParser() const {
        return intrinsic_metadata_from_parser[EGRESS];
    }

    std::vector<IntrinsicField> getEgressIntrinsicMetadataForTM() const {
        return intrinsic_metadata_for_tm[EGRESS];
    }

    std::vector<IntrinsicField> getEgressIntrinsicMetadataForDeparser() const {
        return intrinsic_metadata_for_deparser[EGRESS];
    }

    std::vector<IntrinsicField> getEgressIntrinsicMetadataForOutputPort() const {
        return intrinsic_metadata_for_output_port[EGRESS];
    }

    void add_md(gress_t gress, IntrinsicField f) {
        intrinsic_metadata[gress].push_back(f);
    }

    void add_tm_md(gress_t gress, IntrinsicField f) {
        intrinsic_metadata_for_tm[gress].push_back(f);
    }

    void add_prsr_md(gress_t gress, IntrinsicField f) {
        intrinsic_metadata_from_parser[gress].push_back(f);
    }

    void add_dprsr_md(gress_t gress, IntrinsicField f) {
        intrinsic_metadata_for_deparser[gress].push_back(f);
    }

    void add_outport_md(gress_t gress, IntrinsicField f) {
        intrinsic_metadata_for_output_port[gress].push_back(f);
    }

    std::vector<IntrinsicParam> getParserIntrinsicTypes(gress_t g) const {
        return parser_intrinsic_types[g];
    }

    std::vector<IntrinsicParam> getMAUIntrinsicTypes(gress_t g) const {
        return mauppu_intrinsic_types[g];
    }

    std::vector<IntrinsicParam> getPPUIntrinsicTypes(gress_t g) const {
        return mauppu_intrinsic_types[g];
    }

    std::vector<IntrinsicParam> getDeparserIntrinsicTypes(gress_t g) const {
        return deparser_intrinsic_types[g];
    }

    /** @brief Get the index of the intrinsic metadata for deparser parameter in the deparser.
     *
     * The parameter is the \p ingress_intrinsic_metadata_for_deparser_t or
     * \p egress_intrinsic_metadata_for_deparser_t for the corresponding gress.
     *
     * @return index of the intrinsic metadata for deparser parameter
     */
    int getDeparserIntrinsicMetadataForDeparserParamIndex() const {
        return deparser_intrinsic_metadata_for_deparser_param_index;
    }

    void setTofinoIntrinsicTypes();
};


class TofinoArchSpec : public ArchSpec {
 public:
    TofinoArchSpec();
};

class JBayArchSpec : public ArchSpec {
 public:
    JBayArchSpec();
};

#if HAVE_CLOUDBREAK
class CloudbreakArchSpec : public ArchSpec {
 public:
    CloudbreakArchSpec();
};
#endif

#if HAVE_FLATROCK
class FlatrockArchSpec : public ArchSpec {
 public:
    FlatrockArchSpec();

    void setFlatrockIntrinsicTypes();
};
#endif

#endif  /* EXTENSIONS_BF_P4C_ARCH_ARCH_SPEC_H_ */
