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
    const ClotInfo      &clot;
    indent_t            indent;
    unsigned            checksumIndex = 0;
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
        auto field = phv.field(emit->source->field, &bits);
        if (!field) {
            out << indent << "# no phv: " << *emit << std::endl;
            return false; }

        if (!field->size) {
            /* varbits? not supported */
            LOG3("skipping varbits? " << field->name);
            return false; }

        auto povBit = phv.field(emit->povBit->field);
        auto &alloc = field->for_bit(bits.lo);

        if (!(last == alloc.container && last_pov == povBit)) {
            last = alloc.container;
            last_pov = povBit;

            out << indent << alloc.container;

            if (!povBit) {
                out << indent << " # no phv for pov: " << *emit->povBit << std::endl;
                return false;
            }
            out << ": " << canon_name(trim_asm_name(povBit->name));

            if ((size_t)bits.size() != alloc.container.size())
                out << std::endl;
        }

        out << indent << "    # - " << alloc.container_bits() << ": "
            << DeparserSourceFormatter{field, bits} << std::endl;

        return false;
    }

    bool preorder(const IR::BFN::EmitChecksum* emit) override {
        AutoIndent emitChecksumIndent(indent);
        out << indent << "checksum " << checksumIndex;
        auto povBit = phv.field(emit->povBit->field);
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

        auto povBit = phv.field(emit->povBit->field);
        AutoIndent fieldIndent(indent);
        out << indent << "pov: " << canon_name(trim_asm_name(povBit->name)) << std::endl;

        std::set<PHV::Container> containers;
        for (auto f : emit->clot.phv_fields) {
            f->foreach_alloc([&](const PHV::Field::alloc_slice &alloc) {
                containers.insert(alloc.container);
            });
        }

        unsigned clot_offset = emit->clot.start;
        for (auto c : containers) {
            // TODO(zma) check if c exists
            auto range = clot.container_range_.at(c);
            range = range.shiftedByBytes(-clot_offset);
            out << indent << Range(range.lo, range.hi) << " : " << c << std::endl;
        }

        return false;
    }

    OutputDictionary(std::ostream &out, const PhvInfo &phv, const ClotInfo &clot,
          indent_t initialIndent, unsigned csumIdx)
      : out(out), phv(phv), clot(clot), indent(initialIndent), checksumIndex(csumIdx) { }
};

/// Generates the list of input PHV containers for each deparser checksum
/// computation.
struct OutputChecksums : public Inspector {
    std::ostream        &out;
    const PhvInfo       &phv;
    indent_t            indent;
    unsigned            checksumIndex = 0;

    bool preorder(const IR::BFN::EmitChecksum* emit) override {
        out << indent << "checksum " << checksumIndex << ":" << std::endl;

        AutoIndent checksumIndent(indent);
        PHV::Container lastContainer;
        for (auto* source : emit->sources) {
            bitrange bits;
            auto* field = phv.field(source->field, &bits);
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

            if (Device::currentDevice() == "JBay") {
                auto povBit = phv.field(emit->povBit->field);
                if (!povBit) {
                    out << indent << " # no phv for pov: " << *emit->povBit << std::endl;
                    return false;
                }
                out << ": " << canon_name(trim_asm_name(povBit->name));
            }

            if ((size_t)bits.size() != alloc.container.size())
                out << std::endl << indent << "    # - ";
            else
                out << "  # ";

            out << DeparserSourceFormatter{field, bits} << std::endl;
            lastContainer = alloc.container;
        }

        checksumIndex++;
        return false;
    }

    OutputChecksums(std::ostream &out, const PhvInfo &phv, indent_t initialIndent, unsigned csumIdx)
      : out(out), phv(phv), indent(initialIndent), checksumIndex(csumIdx) { }
};

/// Generates the configuration for the intrinsic deparser parameters.
struct OutputParameters : public Inspector {
    std::ostream        &out;
    const PhvInfo       &phv;
    const indent_t       indent;

    using ParamGroup = std::vector<const IR::BFN::DeparserParameter*>;
    ParamGroup egMulticastGroup;
    ParamGroup hashLagECMP;
    ParamGroup exclusionId;

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
        if (Device::currentDevice() == "JBay" && (param->name == "xid" || param->name == "yid")) {
            exclusionId.push_back(param);
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
        outputParamGroup("xid", exclusionId);
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

        out << indent << digest->name << ":" << std::endl;
        AutoIndent digestIndent(indent);

        int idx = 0;
        for (auto* fieldList : digest->fieldLists) {
            out << indent << idx++ << ": [ ";
            /* learning digest is a bit special here - the driver looks at the first
             * field of the digest to resolve the digest-ID and hence must be appended
             * to the list of digest fields.
             */
            auto* learnIndex = digest->name == "learning" ? digest->selector : nullptr;
            outputFieldlist(fieldList, learnIndex);
            out << " ]" << std::endl;
        }
        auto* selector = digest->selector->field;
        out << indent << "select: " << canon_name(phv.field(selector)->name)
            << std::endl;

        // Only learning digests need context JSON.
        if (digest->name != "learning") return;

        out << indent << "context_json" << ":" << std::endl;
        AutoIndent contextJsonIndent(indent);

        idx = 0;
        for (auto* fieldList : digest->fieldLists) {
            out << indent << idx++ << ": [ ";
            outputContextJson(fieldList);
            out << " ]" << std::endl;
        }

        const char *sep = "";
        out << indent << "name" << ": [ ";
        for (auto* fieldList : digest->fieldLists) {
            out << sep << fieldList->controlPlaneName;
            sep = ", ";
        }
        out << " ]" << std::endl;
    }

    void outputFieldlist(const IR::BFN::DigestFieldList* fieldList,
                         const IR::BFN::FieldLVal* learnIndex) {
        const char* sep = "";

        /* if this is a learning digest, make sure to add lrnindex at the head of
         * this list */
        if (learnIndex) {
            bitrange bits;
            auto *field = phv.field(learnIndex->field, &bits);
            field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &alloc) {
                BUG_CHECK(alloc.container_bit == 0, "bad alignment for container %1%",
                          alloc.container);
                out << sep << alloc.container;
                sep = ", ";
            });
        }

        for (auto* source : fieldList->sources) {
            bitrange bits;
            auto* field = phv.field(source->field, &bits);
            BUG_CHECK(field, "no valid phv allocation for field %1%", source->field);
            field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &alloc) {
                BUG_CHECK(alloc.container_bit == 0, "bad alignment for container %1%",
                          alloc.container);
                out << sep << alloc.container;
                sep = ", ";
            });
        }
    }

    void outputContextJson(const IR::BFN::DigestFieldList* fieldList) {
        const char *sep = "";
        int offset = 0;
        for (auto* source : fieldList->sources) {
            bitrange bits;
            auto* field = phv.field(source->field, &bits);

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

    static int checksumIndex = 0;

    OutputDictionary outputDict(out, d.phv, d.clot, indent, checksumIndex);
    OutputChecksums outputCsum(out, d.phv, indent, checksumIndex);

    d.deparser->apply(outputDict);
    d.deparser->apply(outputCsum);

    BUG_CHECK(outputDict.checksumIndex == outputCsum.checksumIndex, "how many checksums?");

    // XXX(zma) JBay has a global pool of csum engines
    // whereas Tofino's csum engines are assigned to in/egress
    // Adding this temp fix to keep track of global csum index
    if (Device::currentDevice() == "JBay")
        checksumIndex = outputDict.checksumIndex;

    d.deparser->apply(OutputParameters(out, d.phv, indent));
    d.deparser->apply(OutputDigests(out, d.phv, indent));
    return out;
}
