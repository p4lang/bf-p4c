#include "bf-p4c/parde/asm_output.h"
#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/common/autoindent.h"
#include "bf-p4c/phv/phv_fields.h"

struct DeparserSourceFormatter {
    const PHV::Field* dest;
    bitrange bits;
};

std::ostream& operator<<(std::ostream& out, const DeparserSourceFormatter& format) {
    out << canon_name(format.dest->name);
    if (format.bits.lo != 0 || format.bits.hi + 1 != format.dest->size)
        out << '.' << format.bits.lo << '-' << format.bits.hi;
    return out;
}

namespace {

struct OutputDictionary : public Inspector {
    std::ostream        &out;
    const PhvInfo       &phv;
    unsigned            checksumIndex = 0;
    indent_t            indent;
    AutoIndent          autoDictionaryIndent;
    PHV::Container      last;

    bool preorder(const IR::BFN::Emit* emit) override {
        bitrange bits;
        auto field = phv.field(emit->source, &bits);
        if (!field) {
            out << indent << "# no phv: " << *emit << std::endl;
            return false;
        }

        if (!field->size) {
            /* varbits? not supported */
            LOG3("skipping varbits? " << field->name);
            return false; }
        auto &alloc = field->for_bit(bits.lo);
        if (last == alloc.container) {
            out << indent << "    # - " << alloc.container_bits() << ": "
                << DeparserSourceFormatter{field, bits} << std::endl;
            return false;
        }
        last = alloc.container;
        int size = alloc.container.size() / 8;
        if (bits.size() != size * 8)
            out << indent << alloc.container;
        else
            out << indent << DeparserSourceFormatter{field, bits};

        bitrange povAllocBits;
        auto povBit = phv.field(emit->povBit, &povAllocBits);
        if (!povBit) {
            out << indent << " # no phv for pov: " << *emit->povBit << std::endl;
            return false;
        }
        out << ": " << canon_name(trim_asm_name(povBit->name)) << std::endl;

        if (bits.size() != size * 8) {
            out << indent << "    # - " << alloc.container_bits() << ": "
                << DeparserSourceFormatter{field, bits} << std::endl;
        }

        return false;
    }

    bool preorder(const IR::BFN::EmitChecksum* emit) override {
        out << indent << "checksum " << checksumIndex;

        bitrange povAllocBits;
        auto povBit = phv.field(emit->povBit, &povAllocBits);
        if (!povBit) {
            out << indent << " # no phv for pov: " << *emit->povBit << std::endl;
            return false;
        }
        out << ": " << canon_name(trim_asm_name(povBit->name)) << std::endl;

        checksumIndex++;
        return false;
    }

    OutputDictionary(std::ostream &out, const PhvInfo &phv, indent_t initialIndent)
      : out(out), phv(phv), indent(initialIndent), autoDictionaryIndent(indent) { }
};

/// Generates the list of input PHV containers for each deparser checksum
/// computation.
struct OutputChecksums : public Inspector {
    std::ostream        &out;
    const PhvInfo       &phv;
    unsigned            checksumIndex;
    indent_t      indent;

    bool preorder(const IR::BFN::EmitChecksum* emit) override {
        out << indent << "checksum " << checksumIndex << ":" << std::endl;

        AutoIndent checksumIndent(indent);
        PHV::Container lastContainer;
        for (auto* source : emit->sources) {
            bitrange bits;
            auto* field = phv.field(source, &bits);
            if (!field) {
                out << indent << "# no phv: " << source->toString() << std::endl;
                continue;
            }

            auto& alloc = field->for_bit(bits.lo);
            if (alloc.container == lastContainer) {
                out << indent << "    # - " << DeparserSourceFormatter{field, bits}
                    << std::endl;
                continue;
            }

            out << indent << "- " << alloc.container;

            int size = alloc.container.size() / 8;
            if (bits.size() != size * 8)
                out << std::endl << indent << "    # - ";
            else
                out << "  # ";

            out << DeparserSourceFormatter{field, bits} << std::endl;
            lastContainer = alloc.container;
        }

        checksumIndex++;
        return false;
    }

    OutputChecksums(std::ostream &out, const PhvInfo &phv, indent_t initialIndent)
      : out(out), phv(phv), checksumIndex(0), indent(initialIndent) { }
};

/// Generates the configuration for the intrinsic deparser parameters.
struct OutputParameters : public Inspector {
    std::ostream        &out;
    const PhvInfo       &phv;
    const indent_t       indent;

    using ParamGroup = std::vector<const IR::BFN::DeparserParameter*>;
    ParamGroup egMulticastGroup;
    ParamGroup hashLagECMP;

    bool preorder(const IR::BFN::DeparserParameter* param) override {
        // There are a few deparser parameters that need to be grouped in the
        // generated assembly; we save these off to the side and deal with them
        // at the end.
        if (param->name == "mcast_grp_a" || param->name == "mcast_grp_b") {
            egMulticastGroup.push_back(param);
            return false;
        }
        if (param->name == "level1_mcast_hash" || param->name == "level2_mcast_hash") {
            hashLagECMP.push_back(param);
            return false;
        }

        out << indent << param->name << ": ";
        outputParamSource(param);
        out << std::endl;

        return false;
    }

    void postorder(const IR::BFN::Deparser*) override {
        outputParamGroup("egress_multicast_group", egMulticastGroup);
        outputParamGroup("hash_lag_ecmp_mcast", hashLagECMP);
    }

    void outputParamSource(const IR::BFN::DeparserParameter* param) const {
        if (param->povBit) out << "{ ";

        out << canon_name(phv.field(param->source->field)->name);

        if (param->povBit)
            out << ": " << canon_name(phv.field(param->povBit->field)->name)
                        << " }";
    }

    void outputParamGroup(const char* groupName, const ParamGroup& group) {
        if (group.empty()) return;

        out << indent << groupName << ": [ ";

        const char* sep = "";
        for (auto* param : group) {
            out << sep;
            outputParamSource(param);
            sep = ", ";
        }

        out << " ]" << std::endl;
    }

    OutputParameters(std::ostream &out, const PhvInfo &phv, indent_t indent)
      : out(out), phv(phv), indent(indent) { }
};

}  // namespace

void DeparserAsmOutput::emit_fieldlist(std::ostream &out, const IR::Vector<IR::Expression> *list,
                                       const char *sep) const {
    for (auto f : *list) {
        bitrange bits;
        auto* field = phv.field(f, &bits);
        BUG_CHECK(field != nullptr, "no valid phv allocation for field %1%", f);
        field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &alloc) {
            // XXX(hanw)
            // If the fields are not full bytes and the things output in the field list to the
            // assembler must be byte aligned, we need padding to fill it out to bytes, as well
            // as combine any fields that are in the same byte into a single thing in the field
            // list. We will issue a bug for now, assuming we can create a constraint on phv
            // allocation to enforce that field that goes to digest must be aligned to bit zero
            // in all containers.
            BUG_CHECK(alloc.container_bit == 0, "bad alignment for container %1%", alloc.container);

            if (alloc.container && size_t(bits.size()) != alloc.container.size()) {
                out << sep << alloc.container;
            } else {
                out << sep << canon_name(field->name);
                if (bits.lo != 0 || bits.hi + 1 != field->size)
                    out << '.' << bits.lo << '-' << bits.hi;
            }
            sep = ", ";
        });
    }
}

std::ostream &operator<<(std::ostream &out, const DeparserAsmOutput &d) {
    indent_t    indent(1);
    out << "deparser " << d.gress << ":" << std::endl;
    out << indent << "dictionary:";
    if (!d.deparser || d.deparser->emits.empty())
        out << " {}";
    out << std::endl;
    if (!d.deparser)  return out;

    d.deparser->emits.apply(OutputDictionary(out, d.phv, indent));
    d.deparser->emits.apply(OutputChecksums(out, d.phv, indent));
    d.deparser->params.apply(OutputParameters(out, d.phv, indent));

    for (auto digest : Values(d.deparser->digests)) {
        int idx = 0;
        out << indent++ << digest->name << ":" << std::endl;
        for (auto l : digest->sets) {
            out << indent << idx++ << ": [ ";
            d.emit_fieldlist(out, l);
            out << " ]" << std::endl; }
        out << indent-- << "select: " << canon_name(d.phv.field(digest->select)->name)
            << std::endl;
    }

    return out;
}
