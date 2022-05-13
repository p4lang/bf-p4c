#include "bf-p4c/parde/asm_output.h"
#include "bf-p4c/parde/parser_header_sequences.h"

#if HAVE_FLATROCK

namespace {

static int numHeaderIDs = 255;
static int numHeaderSeqs = 2;
static int numHeadersPerSeq = 10;

}  // namespace

HeaderAsmOutput::HeaderAsmOutput(const IR::BFN::Pipe* pipe, const ParserHeaderSequences& seqs)
    : phv(phv), seqs(seqs) {}

/**
 * @brief Outputs the header configuration for Flatrock+
 * 
 * Header configuration is derived from the ingress parser
 */
std::ostream& operator<<(std::ostream& out, const HeaderAsmOutput& headerOut) {
    const auto& seqs = headerOut.seqs;
    if (!seqs.headers.count(INGRESS)) return out;

    BUG_CHECK(seqs.headers.at(INGRESS).size() <= numHeaderIDs,
              "Too many headers parsed by parser: parsed=%1%; allowed=%2%",
              headerOut.seqs.headers.size(), numHeaderIDs);

    indent_t indent(1);
    out << "hdr:" << std::endl;

    // Header map: names to IDs
    out << indent++ << "map:" << std::endl;
    int id = 0;
    for (const auto& hdr : seqs.headers.at(INGRESS))
        out << indent << hdr << ": " << id++ << std::endl;
    indent--;

    // Sequences: ids to header sequences
    // FIXME: Currently taking the first N sequences. Possibly should consider bridged metadata reqs
    // in decided which sequences are compressed vs not.
    if (seqs.sequences.count(INGRESS)) {
        out << indent++ << "seq:" << std::endl;
        id = 0;
        for (const auto& seq : seqs.sequences.at(INGRESS)) {
            if (seq.size() > 0) {
                cstring sep = "";
                std::stringstream ss;
                ss << "[";
                for (const auto& hdr : seq) {
                    ss << sep << hdr;
                    sep = ", ";
                }
                ss << "]";
                BUG_CHECK(seq.size() <= numHeadersPerSeq,
                          "Too many headers in sequence: count=%1% allowed=%2% sequence=%3%",
                          seq.size(), numHeadersPerSeq, ss.str());
                out << indent << id++ << ": " << ss.str() << std::endl;
            }
            if (id >= numHeaderSeqs) {
                out << indent << "# " << (seqs.sequences.at(INGRESS).size() - numHeaderSeqs)
                    << " additional sequence(s) are not compressed" << std::endl;
                break;
            }
        }
        indent--;
    }

    // Lengths: min/max info
    // FIXME: Variable-length headers are currently split; current code ignores this so all
    // headers have been converted to fixed-length.
    out << indent++ << "len:" << std::endl;
    for (const auto& hdr : seqs.headers.at(INGRESS))
        out << indent << hdr << ": { base_len: 0, num_comp_bits: 0, scale: 0 }" << std::endl;
    indent--;

    // FIXME: These shouldn't strictly be necessary. Currently following up with HW team.
    out << indent << "off_pos: 0" << std::endl;
    out << indent << "seq_pos: 1" << std::endl;
    // FIXME: This can't be static as it depends whether the header IDs are compressed or not :(
    out << indent << "len_pos: 2" << std::endl;

    // Simple implementation: take the first numHeaderSeq header sequences
    return out;
}

#endif  /* HAVE_FLATROCK */
