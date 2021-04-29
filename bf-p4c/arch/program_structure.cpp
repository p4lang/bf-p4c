#include "program_structure.h"
#include <set>
#include <algorithm>
#include <boost/iostreams/device/file_descriptor.hpp>
#include <boost/iostreams/stream.hpp>

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
#include "bf-p4c/common/parse_annotations.h"

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

    CompilerOptions options;
    if (filename.startsWith("/"))
        options.file = filename;
    else
        options.file = path.join(filename).toString();

    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    if (FILE *file = options.preprocess()) {
        if (::errorCount() > 0) {
            ::error("Failed to preprocess architecture file %1%", options.file);
            options.closeInput(file);
            return;
        }

        auto code = P4::P4ParserDriver::parse(file, options.file);
        if (code == nullptr || ::errorCount() > 0) {
            ::error("Failed to load architecture file %1%", options.file);
            options.closeInput(file);
            return;
        }
        code = code->apply(BFN::ParseAnnotations());

        for (auto decl : code->objects)
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
        if (auto td = decl->to<IR::Type_Typedef>()) {
            if (auto def = declarations.getDeclaration(td->name)) {
                LOG3("Type " << td->name << " is already defined to "
                                << def->getName() << ", ignored.");
                continue;
            }
        }
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
        if (auto def = declarations.getDeclaration(h.first)) {
            LOG3("Type " << h.first << " is already defined to " << def->getName()
                            << ", ignored.");
            continue;
        }
        declarations.push_back(h.second);
    }
}

void ProgramStructure::createActions() {
    for (auto a : action_types) {
        declarations.push_back(a);
    }
}

}  // namespace BFN
