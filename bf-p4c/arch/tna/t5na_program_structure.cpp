#include "t5na_program_structure.h"
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

const cstring T5naProgramStructure::EXTRA_METADATA_STRING = "_extra_bridged_metadata";

const IR::Type_Name* getTypeFromParam(const IR::Parameter* param) {
    return param->type->to<IR::Type_Name>();
}

cstring getTypeNameFromParam(const IR::Parameter* param) {
    auto pType = getTypeFromParam(param);
    if (!pType) return "";
    return pType->path->name.name;
}

class ReplaceMembers : public Transform {
 public:
    const IR::Node *postorder(IR::Member* mem) {
        auto fullName = mem->toString();
        // Check if we want to change this
        if (!hdrFieldToMd.count(fullName))
            return mem;
        auto repl = hdrFieldToMd[fullName]->clone();
        // Check if this is not one of the assignments that we generated, in which case
        // don't change it
        // It has to be inside Assignment
        auto as = findContext<IR::AssignmentStatement>();
        if (!as)
            return repl;
        // With 2 members
        auto left = as->left->to<IR::Member>();
        auto right = as->right->to<IR::Member>();
        if (!left || !right)
            return repl;
        // Right one is the current member
        // and left is what we would replace it with
        if (right->toString() == fullName &&
            left->toString() == repl->toString()) {
            return mem;
        }
        return repl;
    }

    explicit ReplaceMembers(std::map<cstring, const IR::Member *>& hdrFieldToMd) :
        hdrFieldToMd(hdrFieldToMd) {}

 private:
    std::map<cstring, const IR::Member *>& hdrFieldToMd;
};

const IR::Parameter* updateTypeOfParam(const IR::Parameter* param,
                                       const IR::Type_Name* newType) {
    if (param->type != newType) {
        ::warning("T5NA requires egress and ingress to have the same header/metadata types.\n"
                  "        Type of %1% is changed to %2%.\n"
                  "        This might lead into nonexistent references to fields"
                  " of its previous type!",
                  param, newType);
    }
    return new IR::Parameter(
                    param->srcInfo, param->name,
                    param->annotations, param->direction,
                    newType, param->defaultValue);
}

void T5naProgramStructure::createTypes() {
    for (auto h : type_declarations) {
        auto typeDecl = h.second;
        auto typeName = h.first;
        // Add the type declaration (unless it already exists)
        if (auto def = declarations.getDeclaration(typeName)) {
            LOG3("Type " << typeName << " is already defined to" << def->getName().name
                         << ", ignored.");
            continue;
        }
        // Check if we need to extend this type with generated data
        if (auto typeStruct = typeDecl->to<IR::Type_Struct>()) {
            if (mdTypeExtraFields.count(typeName)) {
                IR::IndexedVector<IR::StructField> newFields;
                newFields.append(typeStruct->fields);
                for (auto s : mdTypeExtraFields[typeName]) {
                    auto newStructName = s->name.name;
                    LOG4("Extending type " << typeName << " with " << s->name.name);
                    newFields.push_back(s);
                    // Also add the new type
                    if (newTypeDeclarations.count(newStructName))
                        declarations.push_back(newTypeDeclarations[newStructName]);
                }
                auto newTypeDecl = new IR::Type_Struct(
                                        typeStruct->srcInfo, typeStruct->name,
                                        typeStruct->annotations, typeStruct->typeParameters,
                                        newFields);
                declarations.push_back(newTypeDecl);
                continue;
            }
        }
        declarations.push_back(typeDecl);
    }
}

void T5naProgramStructure::createParsers() {
    for (auto parser : parsers) {
        auto p = parser.second;
        auto pName = p->name.name;

        // Remove egress only parsers
        if (ingressParsers.count(pName) == 0) {
            LOG3("Removing egress parser " << pName);
            continue;
        }

        auto pType = p->type;
        auto params = pType->getApplyParameters();
        BUG_CHECK(params->size() >= 3, "%1%: Expected at least 3 parameters for parser", pName);

        auto* paramList = new IR::ParameterList;

        auto* packetIn = params->getParameter(0);
        paramList->push_back(packetIn);
        auto* headers = params->getParameter(1);
        paramList->push_back(headers);
        auto* meta = params->getParameter(2);
        paramList->push_back(meta);

        for (unsigned i = 3; i < params->size(); i++) {
            auto param = params->getParameter(i);
            auto name = getTypeNameFromParam(param);
            if (name == "ingress_intrinsic_metadata_t" ||
                name == "ingress_intrinsic_metadata_for_tm_t") {
                paramList->push_back(param);
            // From parser metadata are no longer used
            } else if (name == "ingress_intrinsic_metadata_from_parser_t") {
                ::warning("T5NA no longer uses ingress_intrinsic_metadata_from_parser_t.\n"
                          "         This might lead into nonexistent references to its fields!");
            }
            // Egress metadata are not needed - this parser won't be added anyway
        }

        auto newParserType = new IR::Type_Parser(
                                pType->srcInfo, pType->name, pType->annotations,
                                pType->typeParameters, paramList);
        // New parser with updated applyParams
        auto newParser = new IR::P4Parser(
                            p->srcInfo, p->name,
                            newParserType,
                            p->constructorParams, p->parserLocals,
                            p->states);
        declarations.push_back(newParser);
    }
}

void T5naProgramStructure::createControls() {
    for (auto control : controls) {
        auto c = control.second;
        auto cName = c->name.name;

        bool isIngressDeparser = (ingressDeparsers.count(cName) != 0);
        bool isEgressDeparser = (egressDeparsers.count(cName) != 0);
        bool isIngressControl = (ingressControls.count(cName) != 0);
        bool isEgressControl = (egressControls.count(cName) != 0);

        // Remove controls that are only IngressDeparser
        if (isIngressDeparser && !isEgressDeparser) {
            LOG3("Removing ingress deparser " << cName);
            continue;
        }
        // Check for unsupported ingress/egress sharing
        if (isIngressControl && isEgressControl) {
            ::error("%1%: Control used as both Ingress and Egress, this is impossible"
                    " on T5NA because Ingress does not have inout headers.", c);
        }

        auto cType = c->type;
        auto params = cType->getApplyParameters();
        BUG_CHECK(params->size() >= 2, "%1%: Expected at least 2 parameters for control", cName);
        auto* paramList = new IR::ParameterList;

        // For egress controls we need to change metadata/hdrs to
        // match their Ingress so it can be used together in T5NA pipe
        const IR::Type_Name* iHdrTypeName = nullptr;
        const IR::Type_Name* iMdTypeName = nullptr;
        if (isEgressDeparser || isEgressControl) {
            // If there is no corresponding ingress this
            // is probably not used, just remove it
            if (!correspondingIngress.count(cName))
                continue;
            auto ingress = correspondingIngress[cName];
            CHECK_NULL(ingress);
            auto iType = ingress->type;
            auto iParams = iType->getApplyParameters();
            BUG_CHECK(iParams->size() >= 2, "%1%: Expected at least 2 parameters for control",
                                            ingress->name.name);
            iHdrTypeName = getTypeFromParam(iParams->getParameter(0));
            iMdTypeName = getTypeFromParam(iParams->getParameter(1));
        }

        // This is either packet_out for deparser or hdr for gress
        auto* param = params->getParameter(0);
        // Ingress control need to be fixed
        // since hdrs are no longer inout
        if (isIngressControl) {
            paramList->push_back(
                        new IR::Parameter(
                            param->srcInfo, param->name,
                            param->annotations, IR::Direction::In,
                            param->type, param->defaultValue));
        // Egress control needs to have hdr changed to whatever Ingress uses
        } else if (isEgressControl) {
            paramList->push_back(updateTypeOfParam(param, iHdrTypeName));
        } else {
            paramList->push_back(param);
        }
        // This is either hdr for deparser or md for gress
        param = params->getParameter(1);
        // Once again for Egress we need to update MD type name
        if (isEgressControl) {
            paramList->push_back(updateTypeOfParam(param, iMdTypeName));
        } else if (isEgressDeparser) {
            paramList->push_back(updateTypeOfParam(param, iHdrTypeName));
        } else {
            paramList->push_back(param);
        }

        // For deparser this is md (note that IngressDeparser won't get to this point)
        if (isEgressDeparser) {
            BUG_CHECK(params->size() >= 3, "%1%: Expected at least 3 parameters for deparser",
                                           cName);
            param = params->getParameter(2);
            paramList->push_back(updateTypeOfParam(param, iMdTypeName));
        }

        for (unsigned i = paramList->size(); i < params->size(); i++) {
            auto param = params->getParameter(i);
            auto name = getTypeNameFromParam(param);
            // Ingress metadata that are still in T5NA
            if (name == "ingress_intrinsic_metadata_t" ||
                name == "ingress_intrinsic_metadata_for_tm_t") {
                paramList->push_back(param);
            // From parser/to deparser intrinsic metadata are no longer used
            } else if (name == "ingress_intrinsic_metadata_from_parser_t" ||
                       name == "ingress_intrinsic_metadata_for_deparser_t") {
                ::warning("T5NA doesn't use intrinsic from_parser_t and for_deparser_t metadata.\n"
                          "         This might lead into nonexistent references to it!");
            // Egress from parser metadata are not used anymore in T5NA
            } else if (name == "egress_intrinsic_metadata_from_parser_t") {
                ::warning("T5NA doesn't use egress_intrinsic_metadata_from_parser_t.\n"
                          "         This might lead into nonexistent references to it!");
            // Egress metadata that are still used
            } else if (name == "egress_intrinsic_metadata_t" ||
                       name == "egress_intrinsic_metadata_for_deparser_t" ||
                       name == "egress_intrinsic_metadata_for_output_port_t") {
                paramList->push_back(param);
            }
        }

        // Egress deparser needs a fix
        // eg_intr_md and eg_intr_md_for_dprsr are switched compared to TNA
        // This means that if it is present it is at index 3 instead of 4, where
        // it should be
        if (isEgressDeparser) {
            if (paramList->size() > 3 &&
                getTypeNameFromParam(paramList->getParameter(3)) ==
                    "egress_intrinsic_metadata_for_deparser_t") {
                auto* paramListSwap = new IR::ParameterList;
                paramListSwap->push_back(paramList->getParameter(0));
                paramListSwap->push_back(paramList->getParameter(1));
                paramListSwap->push_back(paramList->getParameter(2));
                // We use egress intrinsic metadata if it exists
                if (paramList->size() == 5) {
                    paramListSwap->push_back(paramList->getParameter(4));
                // Or we create it
                } else {
                    paramListSwap->push_back(
                        new IR::Parameter(
                            "eg_intr_md", IR::Direction::In,
                            new IR::Type_Name(new IR::Path("egress_intrinsic_metadata_t"))));
                }
                // Now we add the egress deparser intrinsic metadata (from index 3)
                // And now they will be will be at index 4
                paramListSwap->push_back(paramList->getParameter(3));
                paramList = paramListSwap;
            }
        }

        // New control with updated applyParams
        auto newControlType = new IR::Type_Control(
                                cType->srcInfo, cType->name, cType->annotations,
                                cType->typeParameters, paramList);
        // Ingress and egress might have new assignments mapping hdrs to metadata
        auto cBody = c->body;
        // New body by default is the same as it was before
        auto newBody = cBody;
        CHECK_NULL(cBody);
        // For ingress and egress that needs it a new one is created
        if ((isIngressControl || isEgressControl) &&
            controlsStatements.count(cName)) {
            IR::IndexedVector<IR::StatOrDecl> newBodyList;
            LOG4("Adding " << controlsStatements[cName].size() <<
                 " header<->metadata assignments to " << cName);
            newBodyList.append(controlsStatements[cName]);
            newBodyList.append(cBody->components);
            newBody = new IR::BlockStatement(cBody->srcInfo, cBody->annotations, newBodyList);
        }
        auto newControl = new IR::P4Control(
                            c->srcInfo, c->name,
                            newControlType,
                            c->constructorParams, c->controlLocals,
                            newBody);
        const IR::Node* finalControl = newControl;
        // Finally in ingresses replace modified hdr usages by
        // their metadata mirrors
        if (isIngressControl) {
            if (hdrFieldToMdMap.count(cName)) {
                ReplaceMembers replaceMembers(hdrFieldToMdMap[cName]);
                finalControl = newControl->apply(replaceMembers);
            }
        }
        declarations.push_back(finalControl);
    }
}

void T5naProgramStructure::createPipeline() {
    for (auto pipe : pipeInstances) {
        auto args = pipe->arguments;
        BUG_CHECK(args->size() == 6, "%1%: Expected 6 arguments for pipe", pipe->name.name);
        // Create new list without ingress deparser and egress parser
        auto* argList = new IR::Vector<IR::Argument>;
        for (unsigned i = 0; i < args->size(); i++) {
            auto arg = args->at(i);
            // Indexed 2 and 3 are ingress deparser and egress parsers, ignore them
            if (i == 2 || i == 3) {
                LOG3("Removing parser/deparser from pipe " << pipe->name.name);
                continue;
            }
            auto cce = arg->expression->to<IR::ConstructorCallExpression>();
            CHECK_NULL(cce);
            // Force rewrite of type (which is the old Parser/Control type) by setting
            // it back to constructedType
            auto newArg = new IR::Argument(
                            arg->srcInfo, arg->name,
                            new IR::ConstructorCallExpression(
                                cce->srcInfo, cce->constructedType,
                                cce->arguments));
            argList->push_back(newArg);
        }
        // Create new type arguments for pipe
        auto pipeType = pipe->type->to<IR::Type_Specialized>();
        CHECK_NULL(pipeType);
        auto typeArgs = pipeType->arguments;
        BUG_CHECK(typeArgs->size() == 4, "%1%: Expected 4 type arguments in type of pipe",
                                          pipe->name.name);
        auto* typeArgList = new IR::Vector<IR::Type>;
        // TNA has 4 types here - IH, IM, EH, EM
        // T5NA only uses H, M (both are the same for Ingress and Egress)
        // We only keep the Ingress ones
        typeArgList->push_back(typeArgs->at(0));
        typeArgList->push_back(typeArgs->at(1));
        auto newPipe = new IR::Declaration_Instance(
                        pipe->srcInfo, pipe->name, pipe->annotations,
                        new IR::Type_Specialized(
                            pipeType->srcInfo, pipeType->baseType,
                            typeArgList),
                        argList, pipe->initializer);
        declarations.push_back(newPipe);
    }
}

void T5naProgramStructure::createMain() {
    auto args = mainInstance->arguments;
    // Create new argument list, where pipe packages are replaced
    auto* argList = new IR::Vector<IR::Argument>;
    for (auto* arg : *args) {
        auto pe = arg->expression->to<IR::PathExpression>();
        CHECK_NULL(pe);
        auto newArg = new IR::Argument(
                        arg->srcInfo, arg->name,
                        new IR::PathExpression(
                            pe->srcInfo,
                            pipePackage,
                            pe->path));
        argList->push_back(newArg);
    }
    // Create new type arguments for Switch
    auto mainInstanceType = mainInstance->type->to<IR::Type_Specialized>();
    CHECK_NULL(mainInstanceType);
    auto typeArgs = mainInstanceType->arguments;
    BUG_CHECK(typeArgs->size() == 16, "Expected 16 type arguments in type of Switch");
    auto* typeArgList = new IR::Vector<IR::Type>;
    // TNA has 4 pipes each with 4 type arguments (IH, IM, EH, EM)
    // T5NA only uses H, M (both are the same for Ingress and Egress)
    for (unsigned i=0; i < typeArgs->size(); i+=4) {
        // Just use IH and IM as H and M
        typeArgList->push_back(typeArgs->at(i));
        typeArgList->push_back(typeArgs->at(i+1));
    }
    // This only gives us first 4 pipelines, we fill out the rest with don't cares
    // T5NA has 16 pipes (each with H and M) => 32 arguments
    for (unsigned i=8; i < 32; i++) {
        typeArgList->push_back(new IR::Type_Dontcare());
    }

    auto newMainInstance = new IR::Declaration_Instance(
                            mainInstance->srcInfo, mainInstance->name,
                            mainInstance->annotations,
                            new IR::Type_Specialized(
                                mainInstanceType->srcInfo, mainInstanceType->baseType,
                                typeArgList),
                            argList, mainInstance->initializer);
    declarations.push_back(newMainInstance);
}

void T5naProgramStructure::createTofinoArch() {
    // Remove tna stuff
    for (auto decl : targetTypesToRemove) {
        if (decl->is<IR::Type_Error>())
            continue;
        else if (auto t = decl->to<IR::Type_Action>()) {
            auto f = std::find(action_types.begin(), action_types.end(), t);
            if (f != action_types.end())
                action_types.erase(f);
        } else if (auto t = decl->to<IR::Type_StructLike>()) {
            type_declarations.erase(t->name);
        } else if (auto t = decl->to<IR::Type_Typedef>()) {
            type_declarations.erase(t->name);
        } else if (auto t = decl->to<IR::Type_Enum>()) {
            enums.erase(t->name);
        } else if (auto t = decl->to<IR::Type_SerEnum>()) {
            ser_enums.erase(t->name);
        }
    }
    // Add T5na stuff
    ProgramStructure::createTofinoArch();
    // Save T5NA package with Pipe definition for later
    for (auto decl : targetTypes) {
        if (auto pkg = decl->to<IR::Type_Package>()){
            if (pkg->name == "Pipeline")
                pipePackage = pkg;
        }
    }
}

const IR::P4Program *T5naProgramStructure::create(const IR::P4Program *program) {
    createErrors();
    createTofinoArch();
    createTypes();
    createActions();
    createParsers();
    createControls();
    createPipeline();
    createMain();

    return new IR::P4Program(program->srcInfo, declarations);
}

}  // namespace BFN
