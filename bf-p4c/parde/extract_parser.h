/*
Copyright 2013-present Barefoot Networks, Inc. 

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#ifndef _TOFINO_PARDE_EXTRACT_PARSER_H_
#define _TOFINO_PARDE_EXTRACT_PARSER_H_

#include "lib/cstring.h"
#include "lib/exceptions.h"
#include "tofino/ir/gress.h"

namespace IR {

namespace Tofino {
class Deparser;
class Parser;
class Pipe;
}  // namespace Tofino

class P4Control;
class P4Parser;

}  // namespace IR

namespace Tofino {

struct ParserInfo {
  const IR::Tofino::Parser* parsers[2] = { nullptr, nullptr };
  const IR::Tofino::Deparser* deparsers[2] = { nullptr, nullptr };
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
ParserInfo extractParser(const IR::Tofino::Pipe* pipe,
                         const IR::P4Parser* igParser,
                         const IR::P4Control* igDeparser,
                         const IR::P4Parser* egParser = nullptr,
                         const IR::P4Control* egDeparser = nullptr);

}  // namespace Tofino

#endif /* _TOFINO_PARDE_EXTRACT_PARSER_H_ */
