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
#include "converters.h"

namespace BFN {

const cstring ProgramStructure::INGRESS_PARSER   = "ingress_parser";
const cstring ProgramStructure::INGRESS          = "ingress";
const cstring ProgramStructure::INGRESS_DEPARSER = "ingress_deparser";
const cstring ProgramStructure::EGRESS_PARSER    = "egress_parser";
const cstring ProgramStructure::EGRESS           = "egress";
const cstring ProgramStructure::EGRESS_DEPARSER  = "egress_deparser";

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

#define TRANSLATE_NODE(NODE, CONVERTER, METHOD) do { \
    for (auto &v : NODE) {                                 \
        CONVERTER cvt(this);                               \
        v.second = cvt.METHOD(v.first);                    \
        LOG3("translated " << v.first << " to " << v.second);}  \
    } while (false)

#define TRANSLATE_EXTERN_INSTANCE(NODE, CONVERTER)      \
    TRANSLATE_NODE(NODE, CONVERTER, convertExternInstance)

#define TRANSLATE_EXTERN_CALL(NODE, CONVERTER)          \
    TRANSLATE_NODE(NODE, CONVERTER, convertExternCall)

#define TRANSLATE_EXTERN_FUNCTION(NODE, CONVERTER)      \
    TRANSLATE_NODE(NODE, CONVERTER, convertExternFunction)

#define TRANSLATE_STATEMENT(NODE, CONVERTER)            \
    TRANSLATE_NODE(NODE, CONVERTER, convert)

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
    for (auto t : typedef_types) {
        declarations.push_back(t.second);
    }
    for (auto h : header_types) {
        declarations.push_back(h.second);
    }
    for (auto h : header_union_types) {
        declarations.push_back(h.second);
    }
    for (auto s : struct_types) {
        declarations.push_back(s.second);
    }
}

void ProgramStructure::createActions() {
    for (auto a : action_types) {
        declarations.push_back(a);
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////

namespace V1 {

void ProgramStructure::createParsers() {
    TRANSLATE_STATEMENT(priorityCalls, ParserPriorityConverter);
    TRANSLATE_STATEMENT(parserCounterCalls, ParserCounterConverter);
    TRANSLATE_STATEMENT(parserCounterSelects, ParserCounterSelectionConverter);

    IngressParserConverter cvt_i(this);
    auto ingressParser = parsers.at(getBlockName(ProgramStructure::INGRESS_PARSER));
    ingressParser = cvt_i.convert(ingressParser);
    declarations.push_back(ingressParser);

    EgressParserConverter cvt_e(this);
    auto egressParser = parsers.at(getBlockName(ProgramStructure::EGRESS_PARSER));
    egressParser = cvt_e.convert(egressParser);
    declarations.push_back(egressParser);
}

void ProgramStructure::createControls() {
    TRANSLATE_EXTERN_INSTANCE(counters, CounterConverter);
    TRANSLATE_EXTERN_INSTANCE(meters, MeterConverter);
    TRANSLATE_EXTERN_INSTANCE(direct_counters, DirectCounterConverter);
    TRANSLATE_EXTERN_INSTANCE(direct_meters, DirectMeterConverter);
    TRANSLATE_STATEMENT(meterCalls, MeterConverter);
    TRANSLATE_EXTERN_FUNCTION(directMeterCalls, DirectMeterConverter);
    TRANSLATE_EXTERN_FUNCTION(hashCalls, HashConverter);
    TRANSLATE_EXTERN_FUNCTION(randomCalls, RandomConverter);

    IngressControlConverter cvt_i(this);
    auto ingress = controls.at(getBlockName(ProgramStructure::INGRESS));
    ingress = cvt_i.convert(ingress);
    declarations.push_back(ingress);

    IngressDeparserConverter cvt_igDep(this);
    auto igDeparser = controls.at(getBlockName(ProgramStructure::INGRESS_DEPARSER));
    igDeparser = cvt_igDep.convert(igDeparser);
    declarations.push_back(igDeparser);

    EgressControlConverter cvt_e(this);
    auto egress = controls.at(getBlockName(ProgramStructure::EGRESS));
    egress = cvt_e.convert(egress);
    declarations.push_back(egress);

    EgressDeparserConverter cvt_egDep(this);
    auto egDeparser = controls.at(getBlockName(ProgramStructure::EGRESS_DEPARSER));
    egDeparser = cvt_egDep.convert(egDeparser);
    declarations.push_back(egDeparser);
}

void ProgramStructure::createMain() {
    auto name = IR::ID(IR::P4Program::main);
    auto typepath = new IR::Path("Switch");
    auto type = new IR::Type_Name(typepath);
    auto typeArgs = new IR::Vector<IR::Type>();
    typeArgs->push_back(new IR::Type_Name(type_h));
    typeArgs->push_back(new IR::Type_Name(type_m));
    typeArgs->push_back(new IR::Type_Name(type_h));
    typeArgs->push_back(new IR::Type_Name(type_m));
    typeArgs->push_back(new IR::Type_Name("compiler_generated_metadata_t"));
    auto typeSpecialized = new IR::Type_Specialized(type, typeArgs);

    auto args = new IR::Vector<IR::Expression>();
    auto emptyArgs = new IR::Vector<IR::Expression>();
    auto iParserPath = new IR::Path("ingressParserImpl");
    auto iParserType = new IR::Type_Name(iParserPath);
    auto iParserConstruct = new IR::ConstructorCallExpression(iParserType, emptyArgs);
    args->push_back(iParserConstruct);

    auto ingressPath = new IR::Path("ingress");
    auto ingressType = new IR::Type_Name(ingressPath);
    auto ingressConstruct = new IR::ConstructorCallExpression(ingressType, emptyArgs);
    args->push_back(ingressConstruct);

    auto iDeparserPath = new IR::Path("ingressDeparserImpl");
    auto iDeparserType = new IR::Type_Name(iDeparserPath);
    auto iDeparserConstruct = new IR::ConstructorCallExpression(iDeparserType, emptyArgs);
    args->push_back(iDeparserConstruct);

    auto eParserPath = new IR::Path("egressParserImpl");
    auto eParserType = new IR::Type_Name(eParserPath);
    auto eParserConstruct = new IR::ConstructorCallExpression(eParserType, emptyArgs);
    args->push_back(eParserConstruct);

    auto egressPath = new IR::Path("egress");
    auto egressType = new IR::Type_Name(egressPath);
    auto egressConstruct = new IR::ConstructorCallExpression(egressType, emptyArgs);
    args->push_back(egressConstruct);

    auto eDeparserPath = new IR::Path("egressDeparserImpl");
    auto eDeparserType = new IR::Type_Name(eDeparserPath);
    auto eDeparserConstruct = new IR::ConstructorCallExpression(eDeparserType, emptyArgs);
    args->push_back(eDeparserConstruct);

    auto result = new IR::Declaration_Instance(name, typeSpecialized, args, nullptr);
    declarations.push_back(result);
}

/// Remap paths, member expressions, and type names according to the mappings
/// specified in the given ProgramStructure.
struct ConvertNames : public PassManager {
    explicit ConvertNames(ProgramStructure *structure) {
        addPasses({new BFN::V1::PathExpressionConverter(structure),
                   new BFN::V1::MemberExpressionConverter(structure),
                   new BFN::V1::TypeNameExpressionConverter(structure)});
    }
};

const IR::P4Program *ProgramStructure::create(const IR::P4Program *program) {
    createErrors();
    createTofinoArch();
    createTypes();
    createActions();
    createParsers();
    createControls();
    createMain();
    auto *convertedProgram = new IR::P4Program(program->srcInfo, declarations);

    // Run a final name conversion pass now that the overall program has been
    // converted.  Some additional opportunities will be exposed once the
    // substitutions performed by all of the `create*()` methods are finished.
    ConvertNames nameConverter(this);
    return convertedProgram->apply(nameConverter);
}

}  // namespace V1

///////////////////////////////////////////////////////////////////////////////////////////////

namespace PSA {

void ProgramStructure::createParsers() {
    IngressParserConverter cvt_i(this);
    auto ingressParser = parsers.at(getBlockName(ProgramStructure::INGRESS_PARSER));
    ingressParser = cvt_i.convert(ingressParser);
    declarations.push_back(ingressParser);

    EgressParserConverter cvt_e(this);
    auto egressParser = parsers.at(getBlockName(ProgramStructure::EGRESS_PARSER));
    egressParser = cvt_e.convert(egressParser);
    declarations.push_back(egressParser);
}


void ProgramStructure::createControls() {
    auto convert = [&](cstring name, ExternConverter& cvt) {
        if (methodcalls.count(name) == 0)
            return;
        auto methodcall = methodcalls[name];
        for (auto &n : methodcall) {
            auto result = cvt.convert(n.first);
            n.second = result;
        }
    };

    IngressControlConverter cvt_i(this);
    auto ingress = controls.at(getBlockName(ProgramStructure::INGRESS));
    ingress = cvt_i.convert(ingress);
    declarations.push_back(ingress);

    IngressDeparserConverter cvt_igDep(this);
    auto igDeparser = controls.at(getBlockName(ProgramStructure::INGRESS_DEPARSER));
    igDeparser = cvt_igDep.convert(igDeparser);
    declarations.push_back(igDeparser);

    EgressControlConverter cvt_e(this);
    auto egress = controls.at(getBlockName(ProgramStructure::EGRESS));
    egress = cvt_e.convert(egress);
    declarations.push_back(egress);

    EgressDeparserConverter cvt_egDep(this);
    auto egDeparser = controls.at(getBlockName(ProgramStructure::EGRESS_DEPARSER));
    egDeparser = cvt_egDep.convert(egDeparser);
    declarations.push_back(egDeparser);
}

void ProgramStructure::createMain() {
    auto name = IR::ID(IR::P4Program::main);
    auto typepath = new IR::Path("Switch");
    auto type = new IR::Type_Name(typepath);
    auto typeArgs = new IR::Vector<IR::Type>();
    typeArgs->push_back(new IR::Type_Name(type_ih));
    typeArgs->push_back(new IR::Type_Name(type_im));
    typeArgs->push_back(new IR::Type_Name(type_eh));
    typeArgs->push_back(new IR::Type_Name(type_em));
    typeArgs->push_back(new IR::Type_Name("compiler_generated_metadata_t"));
    auto typeSpecialized = new IR::Type_Specialized(type, typeArgs);

    auto args = new IR::Vector<IR::Expression>();
    auto emptyArgs = new IR::Vector<IR::Expression>();
    auto iParserPath = new IR::Path("ingressParserImpl");
    auto iParserType = new IR::Type_Name(iParserPath);
    auto iParserConstruct = new IR::ConstructorCallExpression(iParserType, emptyArgs);
    args->push_back(iParserConstruct);

    auto ingressPath = new IR::Path("ingress");
    auto ingressType = new IR::Type_Name(ingressPath);
    auto ingressConstruct = new IR::ConstructorCallExpression(ingressType, emptyArgs);
    args->push_back(ingressConstruct);

    auto iDeparserPath = new IR::Path("ingressDeparserImpl");
    auto iDeparserType = new IR::Type_Name(iDeparserPath);
    auto iDeparserConstruct = new IR::ConstructorCallExpression(iDeparserType, emptyArgs);
    args->push_back(iDeparserConstruct);

    auto eParserPath = new IR::Path("egressParserImpl");
    auto eParserType = new IR::Type_Name(eParserPath);
    auto eParserConstruct = new IR::ConstructorCallExpression(eParserType, emptyArgs);
    args->push_back(eParserConstruct);

    auto egressPath = new IR::Path("egress");
    auto egressType = new IR::Type_Name(egressPath);
    auto egressConstruct = new IR::ConstructorCallExpression(egressType, emptyArgs);
    args->push_back(egressConstruct);

    auto eDeparserPath = new IR::Path("egressDeparserImpl");
    auto eDeparserType = new IR::Type_Name(eDeparserPath);
    auto eDeparserConstruct = new IR::ConstructorCallExpression(eDeparserType, emptyArgs);
    args->push_back(eDeparserConstruct);

    auto result = new IR::Declaration_Instance(name, typeSpecialized, args, nullptr);
    declarations.push_back(result);
}

/// Remap paths, member expressions, and type names according to the mappings
/// specified in the given ProgramStructure.
struct ConvertPsaNames : public PassManager {
    explicit ConvertPsaNames(ProgramStructure *structure) {
        addPasses({new BFN::PSA::PathExpressionConverter(structure),
                   new BFN::PSA::MemberExpressionConverter(structure)});
    }
};

const IR::P4Program *ProgramStructure::create(const IR::P4Program *program) {
    createErrors();
    createTofinoArch();
    createTypes();
    createActions();
    createParsers();
    createControls();
    createMain();
    auto *convertedProgram = new IR::P4Program(program->srcInfo, declarations);

    ConvertPsaNames nameConverter(this);
    return convertedProgram->apply(nameConverter);
}

}  // namespace PSA

}  // namespace BFN
