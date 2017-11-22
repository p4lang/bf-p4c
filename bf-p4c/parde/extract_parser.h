#ifndef BF_P4C_PARDE_EXTRACT_PARSER_H_
#define BF_P4C_PARDE_EXTRACT_PARSER_H_

#include "lib/cstring.h"
#include "lib/exceptions.h"
#include "bf-p4c/ir/gress.h"

namespace IR {

namespace BFN {
class Deparser;
class Parser;
class Pipe;
}  // namespace BFN

class P4Control;
class P4Parser;

}  // namespace IR

namespace BFN {

struct ParserInfo {
  const IR::BFN::Parser* parsers[2] = { nullptr, nullptr };
  const IR::BFN::Deparser* deparsers[2] = { nullptr, nullptr };
};

/**
 * Convert the frontend parser and deparser IR into the representation used in
 * the backend. Special architecture-specific states are automatically added.
 *
 * @param pipe  The pipe into which these parsers will eventually be installed.
 *              The metadata headers must already be configured.
 * @param igParser    The ingress parser.
 * @param igDeparser  The ingress deparser.
 * @param egParser    The egress parser.
 * @param egDeparser  The egress deparser.
 * @return a ParserInfo object containing the Tofino IR parsers and deparsers.
 */
ParserInfo extractParser(const IR::BFN::Pipe* pipe,
                         const IR::P4Parser* igParser,
                         const IR::P4Control* igDeparser,
                         const IR::P4Parser* egParser,
                         const IR::P4Control* egDeparser,
                         bool useTna = false);

}  // namespace BFN

#endif /* BF_P4C_PARDE_EXTRACT_PARSER_H_ */
