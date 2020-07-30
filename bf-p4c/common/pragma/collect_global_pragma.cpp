#include "collect_global_pragma.h"
#include <algorithm>
#include "bf-p4c/common/pragma/all_pragmas.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"

const std::vector<cstring>*
CollectGlobalPragma::g_global_pragma_names = new std::vector<cstring>{
    PragmaAlias::name,
    PragmaAtomic::name,
    PragmaAutoInitMetadata::name,
    PragmaContainerSize::name,
    PragmaContainerType::name,
    PragmaDisableI2EReservedDropImplementation::name,
    PragmaGFMParityEnable::name,
    PragmaMutuallyExclusive::name,
    PragmaNoInit::name,
    PragmaNoOverlay::name,
    PragmaSolitary::name,
    PHV::pragma::DISABLE_DEPARSE_ZERO
};

cstring CollectGlobalPragma::getStructFieldName(const IR::StructField* s) const {
    const auto nameAnnotation = s->annotations->getSingle("name");
    if (!nameAnnotation || nameAnnotation->expr.size() != 1)
        return cstring();
    auto structName = nameAnnotation->expr.at(0)->to<IR::StringLiteral>();
    if (!structName) return cstring();
    return structName->value;
}

bool CollectGlobalPragma::preorder(const IR::StructField* s) {
    if (!s->annotations) return true;
    cstring structFieldName = getStructFieldName(s);
    // The header names are prefixed with a '.'. For the purposes of PHV allocation, we do not need
    // the period.
    cstring structFieldNameWithoutDot = (structFieldName != cstring()) ? structFieldName.substr(1)
                                        : structFieldName;
    for (auto ann : s->annotations->annotations) {
        // Ignore annotations that are not NOT_PARSED or NOT_DEPARSED
        bool notParsedDeparsedAnnotation = (ann->name.name == PHV::pragma::NOT_PARSED ||
                ann->name.name == PHV::pragma::NOT_DEPARSED);
        if (!notParsedDeparsedAnnotation)
            continue;
        if (structFieldName == cstring())
            BUG("Pragma %1% on Struct Field %2% without a name", ann->name.name, s);
        // For the notParsedDeparsedAnnotation, create a new annotation that includes
        // structFieldName.
        if (!ann->expr.size())
            continue;
        const IR::StringLiteral* gress = ann->expr.at(0)->to<IR::StringLiteral>();
        if (!gress || (gress->value != "ingress" && gress->value != "egress")) {
            ::warning("Ignoring @pragma %1% on %2% as it does not apply to ingress or egress",
                      ann->name.name, structFieldNameWithoutDot);
            continue;
        }
        // Create a new annotation that includes the pragma not_parsed or not_deparsed and also adds
        // the name of the header with which the pragma is associated. The format is equivalent to:
        // @pragma not_parsed <gress> <hdr_name>. PHV allocation can then consume this added
        // annotation when implementing the deparsed zero optimization.
        auto* name = new IR::StringLiteral(IR::ID(structFieldNameWithoutDot));
        IR::Annotation* newAnnotation = new IR::Annotation(IR::ID(ann->name.name), {gress, name});
        LOG1("      Adding global annotation: " << newAnnotation);
        global_pragmas_.push_back(newAnnotation);
    }
    return true;
}

bool CollectGlobalPragma::preorder(const IR::Annotation *annotation) {
    auto pragma_name = annotation->name.name;
    bool is_global_pragma = (std::find(g_global_pragma_names->begin(),
                                       g_global_pragma_names->end(), pragma_name)
                             != g_global_pragma_names->end());
    if (is_global_pragma) {
        global_pragmas_.push_back(annotation);
        LOG1("      Adding global annotation: " << annotation);
    }
    return false;
}

const IR::Annotation *CollectGlobalPragma::exists(const char *pragma_name) const {
    const IR::Annotation * pragma = nullptr;
    for (auto p : global_pragmas()) {
        if (p->name == pragma_name) {
            pragma = p;
            break;
        }
    }
    return pragma;
}
