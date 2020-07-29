#include "bf-p4c/parde/asm_output.h"
#include "bf-p4c/common/alias.h"
#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/common/autoindent.h"
#include "bf-p4c/parde/clot/clot_info.h"
#include "bf-p4c/parde/field_packing.h"
#include "bf-p4c/device.h"
#include "lib/hex.h"

namespace {

/// A helper that displays debug information for deparser features. Frequently
/// deparser features included a POV bit, which only show up on certain devices,
/// so this function displays the debug information for both and tries to format
/// the output nicely to find on one line when possible.
std::ostream& outputDebugInfo(std::ostream& out, indent_t indent,
                              const BFN::DebugInfo& sourceDebug,
                              const BFN::DebugInfo& povDebug = BFN::DebugInfo()) {
    AutoIndent debugInfoIndent(indent, 2);

    for (auto& info : sourceDebug.info) {
        if (sourceDebug.info.size() == 1)
            out << "  # ";
        else
            out << std::endl << indent << "# - ";
        out << info;

        if (povDebug.info.size() == 1)
            out << " if " << povDebug.info.back();
    }

    if (povDebug.info.size() > 1) {
        out << std::endl << indent << "# pov:";
        for (auto& info : povDebug.info)
            out << std::endl << indent << "# - " << info;
    }

    return out;
}

/// An `outputDebugInfo()` overload that accepts Reference objects; this often
/// makes calling code less verbose since it's not necessary to null-check the
/// POV bit reference.
std::ostream& outputDebugInfo(std::ostream& out, indent_t indent,
                              const IR::BFN::Reference* sourceRef,
                              const IR::BFN::Reference* povBitRef = nullptr) {
    CHECK_NULL(sourceRef);
    return povBitRef
         ? outputDebugInfo(out, indent, sourceRef->debug, povBitRef->debug)
         : outputDebugInfo(out, indent, sourceRef->debug);
}

/// Generate assembly for the deparser dictionary, which controls which
/// data is written to the output packet.
struct OutputDictionary : public Inspector {
    explicit OutputDictionary(std::ostream& out, const PhvInfo& phv, const ClotInfo& clot) :
        out(out), phv(phv), clot(clot), indent(1) { }

    bool preorder(const IR::BFN::LoweredDeparser* deparser) override {
        out << indent << "dictionary:";
        if (deparser->emits.empty())
            out << " {}";
        out << std::endl;
        return true;
    }

    bool preorder(const IR::BFN::LoweredEmitPhv* emit) override {
        AutoIndent emitIndent(indent);
        out << indent << emit->source << ": " << emit->povBit;
        outputDebugInfo(out, indent, emit->source, emit->povBit) << std::endl;
        return false;
    }

    bool preorder(const IR::BFN::LoweredEmitChecksum* emit) override {
        AutoIndent emitIndent(indent);
        out << indent << "checksum " << emit->unit << ": " << emit->povBit;
        outputDebugInfo(out, indent, emit->povBit) << std::endl;
        return false;
    }

    bool preorder(const IR::BFN::LoweredEmitClot* emit) override {
        return preorder(emit->clot);
    }

    bool preorder(const IR::BFN::LoweredEmitConstant* emit) override {
        AutoIndent emitIndent(indent);
        out << indent << "0x" << hex(emit->constant) << ": " << emit->povBit << std::endl;
        return false;
    }

    bool preorder(const IR::BFN::EmitClot* emit) override {
        AutoIndent autoIndent(indent);
        out << indent << "clot " << emit->clot->tag << ":" << std::endl;

        le_bitrange range;
        auto* povField = phv.field(emit->povBit->field, &range);
        AutoIndent fieldIndent(indent);
        out << indent << "pov: " << canon_name(trim_asm_name(povField->externalName()));
        if (range.size() != povField->size)
            out << "(" << range.lo << ")";
        out << std::endl;

        auto containers = clot.get_overwrite_containers(emit->clot, phv);

        for (auto entry : containers)
            out << indent << entry.first << " : " << entry.second << std::endl;

        auto csum_fields = clot.get_csum_fields(emit->clot);

        for (auto entry : csum_fields) {
            auto offset = entry.first;
            auto f = entry.second;
            BUG_CHECK(emit->clot->csum_field_to_csum_id.count(f),
                      "Checksum field %s is missing a checksum ID in the deparser", f->name);
            out << indent << offset << " : checksum " <<
                emit->clot->csum_field_to_csum_id.at(f) << std::endl;
        }

        return false;
    }

 private:
    std::ostream& out;
    const PhvInfo& phv;
    const ClotInfo& clot;
    indent_t indent;
};

/// Generate assembly which configures the deparser checksum units.
struct OutputChecksums : public Inspector {
    explicit OutputChecksums(std::ostream& out) : out(out), indent(1) { }

    bool preorder(const IR::BFN::ChecksumUnitConfig* checksum) override {
        out << indent << "checksum " << checksum->unit << ": " << std::endl;

        AutoIndent checksumIndent(indent);
        if (checksum->povBit) {
            out << indent <<  "- " << "pov: " <<  checksum->povBit << std::endl;
        }
        if (checksum->zeros_as_ones)
            out << indent << "- " << "zeros_as_ones: " << checksum->zeros_as_ones << std::endl;
        for (auto* input : checksum->phvs) {
            out << indent << "- " << input->source;
            out << ": {";
            if (input->swap != 0) {
                out << " swap: ";
                out << input->swap;
            }
            if (input->povBit) {
                if (input->swap != 0)
                    out << ",";
                out << " pov: ";
                out << input->povBit;
            }
            out << " }";
            outputDebugInfo(out, indent, input->source, input->povBit);
            out << std::endl;
        }

#if HAVE_JBAY
        for (auto* input : checksum->clots) {
            out << indent << "- clot " << input->clot.tag << ": ";
            out << input->povBit << std::endl;
        }
#endif
        return false;
    }

 private:
    std::ostream& out;
    indent_t indent;
};

/// Generate assembly which configures the intrinsic deparser parameters.
struct OutputParameters : public Inspector {
    using ParamGroup = std::map<const int, const IR::BFN::LoweredDeparserParameter*>;

    explicit OutputParameters(std::ostream& out) : out(out), indent(1) { }

    bool preorder(const IR::BFN::LoweredDeparserParameter* param) override {
        // There are a few deparser parameters that need to be grouped in the
        // generated assembly; we save these off to the side and deal with them
        // at the end.
        if (param->name == "mcast_grp_a") {
            egMulticastGroup.emplace(0, param);
            return false; }
        if (param->name == "mcast_grp_b") {
            egMulticastGroup.emplace(1, param);
            return false; }
        if (param->name == "level1_mcast_hash") {
            hashLagECMP.emplace(0, param);
            return false; }
        if (param->name == "level2_mcast_hash") {
            hashLagECMP.emplace(1, param);
            return false; }
        out << indent << param->name << ": ";
        outputParamSource(param);
        outputDebugInfo(out, indent, param->source, param->povBit) << std::endl;

        return false;
    }

    void postorder(const IR::BFN::LoweredDeparser*) override {
        outputParamGroup("egress_multicast_group", egMulticastGroup);
        outputParamGroup("hash_lag_ecmp_mcast", hashLagECMP);
    }

 private:
    void outputParamSource(const IR::BFN::LoweredDeparserParameter* param) const {
        if (param->povBit) out << "{ ";
        out << param->source;
        if (param->povBit) out << ": " << param->povBit << " }";
    }

    void outputParamGroup(const char* groupName, const ParamGroup& group) {
        if (group.empty()) return;

        for (auto &param : group) {
            out << indent << groupName << "_" << param.first << ":" << std::endl;
            AutoIndent paramGroupIndex(indent);
            out << indent << "- ";
            outputParamSource(param.second);
            outputDebugInfo(out, indent, param.second->source, param.second->povBit);
            out << std::endl;
        }
    }

    std::ostream& out;
    indent_t indent;

    ParamGroup egMulticastGroup;
    ParamGroup hashLagECMP;
};

/// Generate the assembly for digests.
struct OutputDigests : public Inspector {
    explicit OutputDigests(std::ostream& out, const PhvInfo&) : out(out), indent(1) { }

    bool preorder(const IR::BFN::LoweredDigest* digest) override {
        out << indent << digest->name << ":" << std::endl;
        AutoIndent digestIndent(indent);

        if (digest->selector) {
            out << indent << "select: ";
            if (digest->povBit) out << "{ ";
            out << digest->selector;
            if (digest->povBit) out << ": " << digest->povBit << " }";

            outputDebugInfo(out, indent, digest->selector) << std::endl;
        }

        for (auto* entry : digest->entries) {
            out << indent << entry->idx << ":";
            if (entry->sources.size() == 0) {
                out << " []" << std::endl;  // output empty list when no params present
                continue;
            }
            out << std::endl;

            /* learning digest is a bit special here - the driver looks at the first
             * field of the digest to resolve the digest-ID and hence must be appended
             * to the list of digest fields.
             * XXX(seth): Actually, this is more or less the same as mirroring. =) We
             * should use the same solution for both. For mirroring, we've
             * already placed the mirror ID in the field list much earlier in
             * the compilation process, and there is no need for any special
             * case here.
             */
            AutoIndent entryIndent(indent);
            if (digest->name == "learning") {
                out << indent << "- " << digest->selector;
                outputDebugInfo(out, indent, digest->selector) << std::endl;
            }

            for (auto* source : entry->sources) {
                out << indent << "- " << source;
                outputDebugInfo(out, indent, source) << std::endl;
            }
        }

        if (digest->name == "learning")
            outputLearningContextJson(digest);

        return false;
    }

 private:
    void outputLearningContextJson(const IR::BFN::LoweredDigest* digest) {
        out << indent << "context_json" << ":" << std::endl;
        AutoIndent contextJsonIndent(indent);

        for (auto* digestEntry : digest->entries) {
            out << indent << digestEntry->idx << ":";

            auto* entry = digestEntry->to<IR::BFN::LearningTableEntry>();
            BUG_CHECK(entry, "Digest table entry isn't a learning table "
                      "entry: %1%", digestEntry);

            if (entry->controlPlaneFormat->size() == 0) {
                out << " []" << std::endl;
                continue;
            }
            out << std::endl;

            // The `context.json` format for learn quanta is a bit uninituitive.
            // The start bit indicates the location of the MSB of each field in
            // little endian order, mod 8. In other words, it specifies the
            // left-most bit in the field, counting from the right - that means
            // it's the highest numbered bit. The start byte is specified in
            // network order; we need to add 1 to compensate for the fact that
            // we don't put the digest ID in the IR representation of the table
            // entry.
            AutoIndent formatIndent(indent);
            for (auto &f : *entry->controlPlaneFormat) {
                out << indent << "- [ " << canon_name(f.fieldName)
                              << ", " << f.startByte + 1            // Start byte.
                              << ", " << f.fieldWidth               // Field width.
                              << ", " << f.startBit                 // Start bit.
                              << ", " << f.fieldOffset              // Field offset.
                              << "]" << std::endl;
            }
        }

        const char* sep = "";
        out << indent << "name" << ": [ ";
        for (auto* entry : digest->entries) {
            out << sep << entry->to<IR::BFN::LearningTableEntry>()
                               ->controlPlaneName;
            sep = ", ";
        }
        out << " ]" << std::endl;
    }

    std::ostream& out;
    indent_t indent;
};

}  // namespace

DeparserAsmOutput::DeparserAsmOutput(const IR::BFN::Pipe* pipe,
                                     const PhvInfo &phv, const ClotInfo &clot,
                                     gress_t gress)
        : phv(phv), clot(clot), deparser(nullptr) {
    auto* abstractDeparser = pipe->thread[gress].deparser;
    BUG_CHECK(abstractDeparser != nullptr, "No deparser?");
    deparser = abstractDeparser->to<IR::BFN::LoweredDeparser>();
    BUG_CHECK(deparser, "Writing assembly for a non-lowered deparser?");
}

std::ostream&
operator<<(std::ostream& out, const DeparserAsmOutput& deparserOut) {
    out << "deparser " << deparserOut.deparser->thread() << ":" << std::endl;
    deparserOut.deparser->apply(OutputDictionary(out, deparserOut.phv, deparserOut.clot));
    deparserOut.deparser->apply(OutputChecksums(out));
    deparserOut.deparser->apply(OutputParameters(out));
    deparserOut.deparser->apply(OutputDigests(out, deparserOut.phv));

    return out;
}