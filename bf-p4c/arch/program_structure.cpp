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

#include <boost/iostreams/device/file_descriptor.hpp>
#include <boost/iostreams/stream.hpp>

#include <set>
#include <algorithm>

#include "ir/ir.h"
#include "lib/path.h"
#include "lib/gmputil.h"

#include "frontends/common/options.h"
#include "frontends/parsers/parserDriver.h"
#include "frontends/p4/reservedWords.h"
#include "frontends/p4/coreLibrary.h"
#include "frontends/p4/tableKeyNames.h"
#include "frontends/p4/cloner.h"

#include "tofino/arch/simple_switch.h"
#include "tofino/arch/converters.h"
#include "tofino/arch/program_structure.h"

namespace P4 {

ProgramStructure::ProgramStructure() {
    declarations = new IR::IndexedVector<IR::Node>();
    tofinoArchTypes = new IR::IndexedVector<IR::Node>();
}

// append target architecture to declaration
void ProgramStructure::include(cstring filename, IR::IndexedVector<IR::Node>* vector) {
    Util::PathName path(p4includePath);
    path = path.join(filename);

    CompilerOptions options;
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    options.file = path.toString();
    if (FILE* file = options.preprocess()) {
        if (!::errorCount()) {
            auto code = P4::P4ParserDriver::parse(options.file, file);
            if (code && !::errorCount())
                for (auto decl : code->declarations)
                    vector->push_back(decl);
        }
        options.closeInput(file);
    }
}

// replace occurrence of v1model intrinsic metadata with tofino metadata
void ProgramStructure::mkTypes() {
    ConvertMetadata cvt(this);
    for (auto h : headers) {
        auto hdr = h->apply(cvt);
        if (hdr->to<IR::Type_Header>())
            declarations->push_back(hdr); }
    for (auto s : structs) {
        auto st = s->apply(cvt);
        if (st->to<IR::Type_Struct>())
            declarations->push_back(st); }
}

// XXX(hanw): only create ingress and egress control block,
// verifyChecksum and updateChecksum is TBD.
void ProgramStructure::mkControls() {
    ConvertControl cvt(this);
    ConvertMetadata mcvt(this);

    for (auto node : controls) {
        node = node->apply(cvt);
        if (!node) continue;
        node = node->apply(mcvt);
        declarations->push_back(node);
    }
}

void ProgramStructure::mkParsers() {
    if (parsers.size() != 1) {
        ::error("V1model program has more than one parser.");
    }
    auto parser = parsers.at(0);

    // the ClonePathExpression pass is necessary to avoid the error in
    // referenceMap where a path is mapped to multiple declarations because
    // ParserConverter create two IR::P4Parser nodes from the same IR::P4Parser
    // node in v1model, and both IR nodes are initialized with the same
    // sub-IR tree.
    ClonePathExpressions cloner;

    // ingress
    ConvertParser icvt(this, gress_t::INGRESS);
    auto igParser = parser->apply(cloner);
    igParser = igParser->apply(icvt);
    declarations->push_back(igParser);

    // egress
    ConvertParser ecvt(this, gress_t::EGRESS);
    auto egParser = parser->apply(cloner);
    egParser = egParser->apply(ecvt);
    declarations->push_back(egParser);
}

// convert deparser to tofino.p4
void ProgramStructure::mkDeparsers() {
    ClonePathExpressions cloner;

    const IR::P4Control* deparser = nullptr;
    for (auto p : controls) {
        // XXX(hanw): name is assumed to be fixed
        if (p->name != "DeparserImpl") continue;
        deparser = p;
        break;
    }
    BUG_CHECK(deparser != nullptr, "Deparser block not implemented.");

    ConvertDeparser icvt(this, gress_t::INGRESS);
    auto igDeparser = deparser->apply(cloner);
    igDeparser = igDeparser->apply(icvt);
    declarations->push_back(igDeparser);

    ConvertDeparser ecvt(this, gress_t::EGRESS);
    auto egDeparser = deparser->apply(cloner);
    egDeparser = egDeparser->apply(ecvt);
    declarations->push_back(egDeparser);
}

void ProgramStructure::mkMain() {
    auto name = IR::ID(IR::P4Program::main);
    auto typepath = new IR::Path("Switch");
    auto type = new IR::Type_Name(typepath);
    auto args = new IR::Vector<IR::Expression>();
    args->push_back(mkConstructorCallExpression("IngressParserImpl"));
    args->push_back(mkConstructorCallExpression("ingress"));
    args->push_back(mkConstructorCallExpression("IngressDeparserImpl"));
    args->push_back(mkConstructorCallExpression("EgressParserImpl"));
    args->push_back(mkConstructorCallExpression("egress"));
    args->push_back(mkConstructorCallExpression("EgressDeparserImpl"));
    auto result = new IR::Declaration_Instance(name, type, args, nullptr);
    declarations->push_back(result);
}

const IR::P4Program* ProgramStructure::translate(Util::SourceInfo info) {
    mkTypes();
    mkParsers();
    mkDeparsers();
    mkControls();
    mkMain();
    auto result = new IR::P4Program(info, *declarations);
    return result;
}

}  // namespace P4
