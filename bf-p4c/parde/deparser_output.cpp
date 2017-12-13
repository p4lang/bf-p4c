#include "bf-p4c/parde/asm_output.h"
#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/common/autoindent.h"
#include "bf-p4c/parde/field_packing.h"

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
    explicit OutputDictionary(std::ostream& out) : out(out), indent(1) { }

    bool preorder(const IR::BFN::LoweredDeparser* deparser) override {
        out << indent << "dictionary:";
        if (deparser->emits.empty()) out << " {}";
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
        AutoIndent emitIndent(indent);
        out << indent << "clot " << emit->tag << ":" << std::endl;

        AutoIndent clotDetailsIndent(indent);
        out << indent << "pov: " << emit->povBit;
        outputDebugInfo(out, indent, emit->povBit) << std::endl;
        out << indent << "length: " << emit->byteLength << std::endl;

        for (auto* phvOverride : emit->overrides) {
            out << indent << phvOverride->range.lo << ": " << phvOverride->source;
            outputDebugInfo(out, indent, phvOverride->source) << std::endl;
        }

        return false;
    }

 private:
    std::ostream& out;
    indent_t indent;
};

/// Generate assembly which configures the deparser checksum units.
struct OutputChecksums : public Inspector {
    explicit OutputChecksums(std::ostream& out) : out(out), indent(1) { }

    bool preorder(const IR::BFN::ChecksumUnitConfig* checksum) override {
        out << indent << "checksum " << checksum->unit << ":" << std::endl;

        AutoIndent checksumIndent(indent);
        for (auto* input : checksum->inputs) {
            out << indent << "- " << input->source;
            if (input->povBit) out << ": " << input->povBit;
            outputDebugInfo(out, indent, input->source, input->povBit);
            out << std::endl;
        }

        return false;
    }

 private:
    std::ostream& out;
    indent_t indent;
};

/// Generate assembly which configures the intrinsic deparser parameters.
struct OutputParameters : public Inspector {
    using ParamGroup = std::vector<const IR::BFN::LoweredDeparserParameter*>;

    explicit OutputParameters(std::ostream& out) : out(out), indent(1) { }

    bool preorder(const IR::BFN::LoweredDeparserParameter* param) override {
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
        if (Device::currentDevice() == "JBay" &&
              (param->name == "xid" || param->name == "yid")) {
            exclusionId.push_back(param);
            return false;
        }

        out << indent << param->name << ": ";
        outputParamSource(param);
        outputDebugInfo(out, indent, param->source, param->povBit) << std::endl;

        return false;
    }

    void postorder(const IR::BFN::LoweredDeparser*) override {
        outputParamGroup("egress_multicast_group", egMulticastGroup);
        outputParamGroup("hash_lag_ecmp_mcast", hashLagECMP);
        outputParamGroup("xid", exclusionId);
    }

 private:
    void outputParamSource(const IR::BFN::LoweredDeparserParameter* param) const {
        if (param->povBit) out << "{ ";
        out << param->source;
        if (param->povBit) out << ": " << param->povBit << " }";
    }

    void outputParamGroup(const char* groupName, const ParamGroup& group) {
        if (group.empty()) return;

        out << indent << groupName << ":" << std::endl;

        AutoIndent paramGroupIndex(indent);
        for (auto* param : group) {
            out << indent << "- ";
            outputParamSource(param);
            outputDebugInfo(out, indent, param->source, param->povBit);
            out << std::endl;
        }
    }

    std::ostream& out;
    indent_t indent;

    ParamGroup egMulticastGroup;
    ParamGroup hashLagECMP;
    ParamGroup exclusionId;
};

/// Generate the assembly for digests.
struct OutputDigests : public Inspector {
    explicit OutputDigests(std::ostream& out) : out(out), indent(1) { }

    bool preorder(const IR::BFN::LoweredDigest* digest) override {
        out << indent << digest->name << ":" << std::endl;
        AutoIndent digestIndent(indent);

        out << indent << "select: " << digest->selector;
        outputDebugInfo(out, indent, digest->selector) << std::endl;

        int idx = 0;
        for (auto* entry : digest->entries) {
            out << indent << idx++ << ":" << std::endl;

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

        int idx = 0;
        for (auto* digestEntry : digest->entries) {
            out << indent << idx++ << ":" << std::endl;

            auto* entry = digestEntry->to<IR::BFN::LearningTableEntry>();
            BUG_CHECK(entry, "Digest table entry isn't a learning table "
                      "entry: %1%", digestEntry);

            // The `context.json` format for learn quanta is a bit uninituitive.
            // The start bit indicates the location of the MSB of each field in
            // little endian order, mod 8. In other words, it specifies the
            // left-most bit in the field, counting from the right - that means
            // it's the highest numbered bit. The start byte is specified in
            // network order; we need to add 1 to compensate for the fact that
            // we don't put the digest ID in the IR representation of the table
            // entry.
            AutoIndent formatIndent(indent);
            entry->controlPlaneFormat->forEachField<Endian::Network>(
              [&](nw_bitrange range, const IR::Expression*, cstring fieldName) {
                le_bitrange leRange = range.toOrder<Endian::Little>(
                    entry->controlPlaneFormat->totalWidth);
                out << indent << "- [ " << canon_name(fieldName)
                              << ", " << (leRange.hi % 8)    // Start bit.
                              << ", " << range.size()        // Field size.
                              << ", " << range.loByte() + 1  // Start byte.
                              << "]" << std::endl;
            });
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
                                     gress_t gress)
        : deparser(nullptr) {
    auto* abstractDeparser = pipe->thread[gress].deparser;
    BUG_CHECK(abstractDeparser != nullptr, "No deparser?");
    deparser = abstractDeparser->to<IR::BFN::LoweredDeparser>();
    BUG_CHECK(deparser, "Writing assembly for a non-lowered deparser?");
}

std::ostream&
operator<<(std::ostream& out, const DeparserAsmOutput& deparserOut) {
    out << "deparser " << deparserOut.deparser->thread() << ":" << std::endl;

    deparserOut.deparser->apply(OutputDictionary(out));
    deparserOut.deparser->apply(OutputChecksums(out));
    deparserOut.deparser->apply(OutputParameters(out));
    deparserOut.deparser->apply(OutputDigests(out));

    return out;
}
