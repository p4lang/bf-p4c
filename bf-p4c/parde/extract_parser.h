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
 * the Tofino backend. Special Tofino-specific states are automatically added.
 *
 * XXX(seth): We shouldn't really be doing any inferring here. Long term we
 * should be converting both P4-14 and v1model P4-16 programs to TNA, and any
 * inference should happen as part of those conversions.
 *
 * @param pipe  The pipe into which these parsers will eventually be installed.
 *              The metadata headers must already be configured.
 * @param igParser    The ingress parser. Required.
 * @param igDeparser  The ingress deparser. Required.
 * @param egParser    The egress parser. If null, will be inferred from the
 *                    ingress parser.
 * @param egDeparser  The egress deparser. If null, will be inferred from the
 *                    egress parser.
 * @return a ParserInfo object containing the Tofino IR parsers and deparsers.
 */
ParserInfo extractParser(const IR::BFN::Pipe* pipe,
                         const IR::P4Parser* igParser,
                         const IR::P4Control* igDeparser,
                         const IR::P4Parser* egParser = nullptr,
                         const IR::P4Control* egDeparser = nullptr);

}  // namespace BFN

#endif /* BF_P4C_PARDE_EXTRACT_PARSER_H_ */
