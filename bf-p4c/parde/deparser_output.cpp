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
    PHV::Container      last;
    const PHV::Field    *last_pov;

    bool preorder(const IR::BFN::Deparser* deparser) override {
        out << indent << "dictionary:";
        if (deparser->emits.empty()) out << " {}";
        out << std::endl;
        return true;
    }

    bool preorder(const IR::BFN::Emit* emit) override {
        AutoIndent emitIndent(indent);
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

        bitrange povAllocBits;
        auto povBit = phv.field(emit->povBit, &povAllocBits);
        auto &alloc = field->for_bit(bits.lo);
        int size = alloc.container.size() / 8;
        if (last == alloc.container && last_pov == povBit) {
            out << indent << "    # - " << alloc.container_bits() << ": "
                << DeparserSourceFormatter{field, bits} << std::endl;
            return false; }
        last = alloc.container;
        last_pov = povBit;
        if (bits.size() != size * 8)
            out << indent << alloc.container;
        else
            out << indent << DeparserSourceFormatter{field, bits};

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
        AutoIndent emitChecksumIndent(indent);
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

    bool preorder(const IR::BFN::EmitClot* emit) override {
        AutoIndent autoIndent(indent);
        out << indent << "clot " << emit->clot.tag << ":" << std::endl;
        bitrange povAllocBits;
        auto povBit = phv.field(emit->povBit, &povAllocBits);
        AutoIndent fieldIndent(indent);
        out << indent << "pov: " << canon_name(trim_asm_name(povBit->name)) << std::endl;
        for (auto f : emit->clot.phv_fields)
            out << indent << emit->clot.offset(f) << " : " <<  canon_name(f->name) << std::endl;
        return false;
    }

    OutputDictionary(std::ostream &out, const PhvInfo &phv, indent_t initialIndent)
      : out(out), phv(phv), indent(initialIndent) { }
};

/// Generates the list of input PHV containers for each deparser checksum
/// computation.
struct OutputChecksums : public Inspector {
    std::ostream        &out;
    const PhvInfo       &phv;
    unsigned            checksumIndex;
    indent_t            indent;

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

/// Generate digest field list
class OutputDigests : public Inspector {
    std::ostream        &out;
    const PhvInfo       &phv;
    indent_t             indent;

    void postorder(const IR::BFN::Digest* digest) override {
        LOG1("emit digest " << digest << " name " << digest->name);

        int idx = 0;
        out << indent++ << digest->name << ":" << std::endl;
        for (auto l : digest->sets) {
            out << indent << idx++ << ": [ ";
            outputFieldlist(l);
            out << " ]" << std::endl;
        }
        out << indent << "select: " << canon_name(phv.field(digest->select)->name)
            << std::endl;

        // resubmit, clone digest has no control plane names
        // do not generate context json for them.
        if (digest->controlPlaneNames.size() == 0)
            return;

        idx = 0;
        out << indent++ << "context_json" << ":" << std::endl;
        for (auto l : digest->sets) {
            out << indent << idx++ << ": [ ";
            outputContextJson(l);
            out << " ]" << std::endl;
        }

        const char *sep = "";
        out << indent << "name" << ": [ ";
        for (auto l : digest->controlPlaneNames) {
            out << sep << l;
            sep = ", ";
        }
        out << " ]" << std::endl;
    }

    void outputFieldlist(const IR::Vector<IR::Expression> *list) {
        const char* sep = "";
        for (auto f : *list) {
            bitrange bits;
            auto* field = phv.field(f, &bits);
            BUG_CHECK(field != nullptr, "no valid phv allocation for field %1%", f);
            field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &alloc) {
                BUG_CHECK(alloc.container_bit == 0, "bad alignment for container %1%",
                          alloc.container);
                out << sep << alloc.container;
                sep = ", ";
            });
        }
    }

    void outputContextJson(const IR::Vector<IR::Expression> *list) {
        const char *sep = "";
        int offset = 0;
        for (auto f : *list) {
            bitrange bits;
            auto* field = phv.field(f, &bits);

            out << sep << "[ " << canon_name(trim_asm_name(field->name)) << ", "
                << bits.lo << ", " << bits.size() << ", " << offset << "]";

            field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &alloc) {
                offset += alloc.container.size() / 8;
            });

            sep = ", ";
        }
    }

 public:
    OutputDigests(std::ostream &out, const PhvInfo &phv, indent_t indent)
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
    BUG_CHECK(d.deparser, "No deparser?");

    out << "deparser " << d.gress << ":" << std::endl;
    indent_t indent(1);
    d.deparser->apply(OutputDictionary(out, d.phv, indent));
    d.deparser->apply(OutputChecksums(out, d.phv, indent));
    d.deparser->apply(OutputParameters(out, d.phv, indent));
    d.deparser->apply(OutputDigests(out, d.phv, indent));
    return out;
}
