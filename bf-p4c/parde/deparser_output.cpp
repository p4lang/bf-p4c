#include "bf-p4c/parde/asm_output.h"
#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/phv/phv_fields.h"

// XXX(seth): This duplicates the very similar ExtractDestFormatter class in
// parser_output.cpp; we need to combine them.
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

class OutputDictionary : public Inspector {
    std::ostream        &out;
    const PhvInfo       &phv;
    unsigned            checksumIndex = 0;
    indent_t            indent;
    PHV::Container      last;
    bool preorder(const IR::BFN::Emit* emit) {
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

    bool preorder(const IR::BFN::EmitChecksum* emit) {
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

 public:
    OutputDictionary(std::ostream &out, const PhvInfo &phv, indent_t indent)
    : out(out), phv(phv), indent(indent) {}
};

/// Generates the list of input PHV containers for each deparser checksum
/// computation.
class OutputChecksums : public Inspector {
    std::ostream        &out;
    const PhvInfo       &phv;
    unsigned            checksumIndex;
    indent_t            indent;

    bool preorder(const IR::BFN::EmitChecksum* emit) {
        out << indent << "checksum " << checksumIndex << ":" << std::endl;

        indent++;
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
        indent--;

        checksumIndex++;
        return false;
    }

 public:
    OutputChecksums(std::ostream &out, const PhvInfo &phv, indent_t indent)
    : out(out), phv(phv), checksumIndex(0), indent(indent) {}
};

void DeparserAsmOutput::emit_fieldlist(std::ostream &out, const IR::Vector<IR::Expression> *list,
                                       const char *sep) const {
    PHV::Container last;
    for (auto f : *list) {
        bitrange bits;
        if (auto field = phv.field(f, &bits)) {
            auto &alloc = field->for_bit(bits.lo);
            if (last && alloc.container == last)
                continue;
            last = alloc.container;
            if (alloc.container && size_t(bits.size()) != alloc.container.size()) {
                out << sep << alloc.container;
            } else {
                out << sep << canon_name(field->name);
                if (bits.lo != 0 || bits.hi + 1 != field->size)
                    out << '.' << bits.lo << '-' << bits.hi; }
            sep = ", "; } }
}

class printIntrin {
    const PhvInfo &phv;
    const IR::BFN::DeparserIntrinsic &di;
    friend std::ostream &operator<<(std::ostream &out, const printIntrin &p) {
        if (p.di.povBit) {
            out << "{ " << canon_name(p.phv.field(p.di.value)->name) << ": "
                << canon_name(p.phv.field(p.di.povBit)->name) << " }";
        } else {
            out << canon_name(p.phv.field(p.di.value)->name); }
        return out; }
 public:
    printIntrin(const PhvInfo &p, const IR::BFN::DeparserIntrinsic *d) : phv(p), di(*d) {}
};

std::ostream &operator<<(std::ostream &out, const DeparserAsmOutput &d) {
    indent_t    indent(1);
    out << "deparser " << d.gress << ":" << std::endl;
    out << indent << "dictionary:";
    if (!d.deparser || d.deparser->emits.empty())
        out << " {}";
    out << std::endl;
    if (d.deparser) {
        d.deparser->emits.apply(OutputDictionary(out, d.phv, ++indent));
        --indent;

        // XXX(zma) "egress_multicast_group" is an exception that can have multiple elements,
        // the following block of code deals with this exception.
        std::vector<std::pair<const cstring, const IR::BFN::DeparserIntrinsic *>>
            egress_multicast_group;

        std::vector<std::pair<const cstring, const IR::BFN::DeparserIntrinsic *>>
                      hash_lag_ecmp_mcast;
        for (auto md : d.deparser->metadata) {
            if (md.first == "egress_multicast_group_a" ||
                md.first == "egress_multicast_group_b") {
                 egress_multicast_group.push_back(md);
                 continue;
            }

            if (md.first == "hash_lag_ecmp_mcast_1" ||
                md.first == "hash_lag_ecmp_mcast_2") {
                    hash_lag_ecmp_mcast.push_back(md);
                    continue;
            }

            out << indent << md.first << ": " << printIntrin(d.phv, md.second) << std::endl;
        }
        if (egress_multicast_group.size() == 2) {
            out << indent << "egress_multicast_group: [ ";
            out << printIntrin(d.phv, egress_multicast_group[0].second) << ", ";
            out << printIntrin(d.phv, egress_multicast_group[1].second) << " ]"
                << std::endl;
        } else if (egress_multicast_group.size() == 1) {
            out << indent << "egress_multicast_group: "
                << printIntrin(d.phv, egress_multicast_group[0].second)
                << std::endl;
        }

        if (hash_lag_ecmp_mcast.size() == 2) {
            out << indent << "hash_lag_ecmp_mcast: [ ";
            out << printIntrin(d.phv, hash_lag_ecmp_mcast[0].second) << ", ";
            out << printIntrin(d.phv, hash_lag_ecmp_mcast[1].second) << " ]" << std::endl;
        }

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
        d.deparser->emits.apply(OutputChecksums(out, d.phv, indent));
    }
    return out;
}
