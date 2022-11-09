#include "bf-p4c/common/flatrock.h"
#include "bf-p4c/parde/asm_output.h"
#include "bf-p4c/parde/parser_header_sequences.h"

#if HAVE_FLATROCK

HeaderAsmOutput::HeaderAsmOutput(const ParserHeaderSequences& seqs) : seqs(seqs) {}

/**
 * @ingroup AsmOutput
 * 
 * @brief Outputs the header configuration for Flatrock+
 *
 * The header configuration specifies the headers that are identified by the parser. This
 * configuration is derived from the ingress parser.
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
    for (const auto& hdr : seqs.header_ids)
        out << indent << hdr.first.second << ": " << hdr.second << std::endl;
    indent--;

    // Sequences: ids to header sequences
    // FIXME: Currently taking the first N sequences. Possibly should consider bridged metadata reqs
    // in decided which sequences are compressed vs not.
    if (seqs.sequences.count(INGRESS)) {
        out << indent++ << "seq:" << std::endl;
        unsigned int id = 0;
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
            if (id == Flatrock::MDP_HDR_ID_COMP_ROWS) {
                if (seqs.sequences.at(INGRESS).size() > Flatrock::MDP_HDR_ID_COMP_ROWS) {
                    out << indent << "# " <<
                        (seqs.sequences.at(INGRESS).size() - Flatrock::MDP_HDR_ID_COMP_ROWS) <<
                        " additional sequence(s) are not compressed" << std::endl;
                }
                break;
            }
        }
        indent--;
    }

    // Lengths: min/max info
    // FIXME: Variable-length headers are currently split; current code ignores this so all
    // headers have been converted to fixed-length.
    out << indent++ << "len:" << std::endl;
    for (const auto& hdr : seqs.headers.at(INGRESS)) {
        const auto it = seqs.header_sizes.find(hdr);
        BUG_CHECK(it != seqs.header_sizes.end(), "Could not find size for header %1%", hdr);
        out << indent << hdr << ": { base_len: " << it->second / 8
            << ", num_comp_bits: 0, scale: 0 }" << std::endl;
    }
    indent--;

    // Simple implementation: take the first numHeaderSeq header sequences
    return out;
}

#endif  /* HAVE_FLATROCK */
