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

#include "program_structure.h"
#include <boost/iostreams/device/file_descriptor.hpp>
#include <boost/iostreams/stream.hpp>
#include <set>
#include <algorithm>

#include "ir/ir.h"
#include "lib/path.h"
#include "lib/gmputil.h"

#include "frontends/common/options.h"
#include "frontends/common/parseInput.h"
#include "frontends/common/constantFolding.h"
#include "frontends/parsers/parserDriver.h"
#include "frontends/p4/reservedWords.h"
#include "frontends/p4/coreLibrary.h"
#include "frontends/p4/tableKeyNames.h"
#include "frontends/p4/cloner.h"
#include "frontends/p4/fromv1.0/converters.h"
#include "frontends/p4-14/header_type.h"
#include "frontends/p4-14/typecheck.h"

namespace Tofino {

// append target architecture to declaration
void ProgramStructure::include(cstring filename, IR::IndexedVector<IR::Node>* vector) {
    Util::PathName path(p4includePath);
    path = path.join(filename);

    CompilerOptions options;
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    options.file = path.toString();
    if (FILE* file = options.preprocess()) {
        if (::errorCount() > 0) {
            ::error("Failed to preprocess architecture file %1%", options.file);
            return;
        }

        auto code = P4::P4ParserDriver::parse(options.file, file);
        if (code == nullptr || ::errorCount() > 0) {
            ::error("Failed to load architecture file %1%", options.file);
            return;
        }

        for (auto decl : code->declarations)
            vector->push_back(decl);
        options.closeInput(file);
    }
}

/// Following is a simplified version of P4-14 to P4-16 converter that just
/// converts included header files.
namespace {
class V1DiscoverStructure : public Inspector {
    P4V1::ProgramStructure *structure;

 public:
    explicit V1DiscoverStructure(P4V1::ProgramStructure *structure) : structure(structure) {
        CHECK_NULL(structure);
        setName("DiscoverStructure");
    }

    void postorder(const IR::Metadata *md) override { structure->metadata.emplace(md); }
    void postorder(const IR::Header *hd) override { structure->headers.emplace(hd); }
    void postorder(const IR::Type_StructLike *t) override { structure->types.emplace(t); }
    void postorder(const IR::Type_Extern *ext) override { structure->extern_types.emplace(ext); }
};

class V1Rewrite : public Transform {
    P4V1::ProgramStructure *structure;

 public:
    explicit V1Rewrite(P4V1::ProgramStructure *structure) : structure(structure) {
        CHECK_NULL(structure);
        setName("V1Rewrite");
    }

    const IR::Node *preorder(IR::V1Program *global) override {
        prune();
        structure->createTypes();
        structure->createExterns();
        auto result = new IR::P4Program(global->srcInfo, *structure->declarations);
        LOG1("V1Rewrite " << result);
        return result;
    }
};

// @input: P4 v1.0 partial program
// @output: P4 v1.2 partial program
class V1Converter : public PassManager {
    P4V1::ProgramStructure structure;

 public:
    V1Converter() {
        setName("V1Converter");
        passes.emplace_back(new P4::DoConstantFolding(nullptr, nullptr));
        passes.emplace_back(new CheckHeaderTypes());
        passes.emplace_back(new TypeCheck());
        passes.emplace_back(new V1DiscoverStructure(&structure));
        passes.emplace_back(new V1Rewrite(&structure));
    }
};

}  // namespace

void ProgramStructure::include14(cstring filename, IR::IndexedVector<IR::Node>* vector) {
    Util::PathName path(p4_14includePath);
    path = path.join(filename);

    CompilerOptions options;
    options.langVersion = CompilerOptions::FrontendVersion::P4_14;
    options.file = path.toString();
    if (FILE* file = options.preprocess()) {
        if (::errorCount() > 0) {
            ::error("Failed to preprocess library file %1%", options.file);
            return; }

        V1Converter converter;
        const IR::Node* v1 = V1::V1ParserDriver::parse(options.file, file);
        v1 = v1->apply(converter);
        if (v1 == nullptr) {
            ::error("Failed to load library file %1%", options.file);
            return; }

        auto program = v1->to<IR::P4Program>();
        for (auto decl : program->declarations)
            vector->push_back(decl);
        options.closeInput(file);
    }
}

}  // namespace Tofino
