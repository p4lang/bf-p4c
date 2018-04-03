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

namespace BFN {

const cstring ProgramStructure::INGRESS_PARSER = "ingress_parser";
const cstring ProgramStructure::INGRESS = "ingress";
const cstring ProgramStructure::INGRESS_DEPARSER = "ingress_deparser";
const cstring ProgramStructure::EGRESS_PARSER = "egress_parser";
const cstring ProgramStructure::EGRESS = "egress";
const cstring ProgramStructure::EGRESS_DEPARSER = "egress_deparser";

// append target architecture to declaration
void ProgramStructure::include(cstring filename, IR::IndexedVector<IR::Node> *vector) {
    // the p4c driver sets environment variables for include
    // paths.  check the environment and add these to the command
    // line for the preporicessor
    char *drvP4IncludePath = getenv("P4C_16_INCLUDE_PATH");
    Util::PathName path(drvP4IncludePath ? drvP4IncludePath : p4includePath);
    path = path.join(filename);

    CompilerOptions options;
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    options.file = path.toString();
    if (FILE *file = options.preprocess()) {
        if (::errorCount() > 0) {
            ::error("Failed to preprocess architecture file %1%", options.file);
            return;
        }

        auto code = P4::P4ParserDriver::parse(file, options.file);
        if (code == nullptr || ::errorCount() > 0) {
            ::error("Failed to load architecture file %1%", options.file);
            return;
        }

        for (auto decl : code->declarations)
            vector->push_back(decl);
        options.closeInput(file);
    }
}

cstring ProgramStructure::getBlockName(cstring name) {
    BUG_CHECK(blockNames.find(name) != blockNames.end(),
              "Cannot find block %1% in package", name);
    auto blockname = blockNames.at(name);
    return blockname;
}

void ProgramStructure::createTofinoArch() {
    for (auto decl : targetTypes) {
        if (decl->is<IR::Type_Error>())
            continue;
        declarations.push_back(decl);
    }
}

void ProgramStructure::createErrors() {
    auto allErrors = new IR::IndexedVector<IR::Declaration_ID>();
    for (auto e : errors) {
        allErrors->push_back(new IR::Declaration_ID(e));
    }
    declarations.push_back(new IR::Type_Error("error", *allErrors));
}

void ProgramStructure::createTypes() {
    for (auto h : type_declarations) {
        declarations.push_back(h.second);
    }
}

void ProgramStructure::createActions() {
    for (auto a : action_types) {
        declarations.push_back(a);
    }
}

}  // namespace BFN
