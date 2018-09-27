#include <limits.h>
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <initializer_list>
#include <map>
#include <set>
#include "lib/bitops.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/strengthReduction.h"
#include "frontends/p4/uselessCasts.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "bf-p4c/arch/bridge_metadata.h"
#include "bf-p4c/arch/intrinsic_metadata.h"
#include "bf-p4c/arch/phase0.h"
#include "bf-p4c/arch/program_structure.h"
#include "bf-p4c/arch/remove_set_metadata.h"
#include "bf-p4c/arch/v1model.h"
#include "bf-p4c/device.h"

namespace BFN {

//////////////////////////////////////////////////////////////////////////////////////////////
namespace V1 {

class FixupBackwardCompatibility : public Transform {
 public:
    FixupBackwardCompatibility() {}

    const IR::Node* postorder(IR::Parameter* param) {
        auto ctxt = findOrigCtxt<IR::Type_Control>();
        if (!ctxt) return param;
        if (ctxt->name != "Egress") return param;
        if (auto tn = param->type->to<IR::Type_Name>()) {
            if (tn->path->name != "egress_intrinsic_metadata_t")
                return param;
            param->direction = IR::Direction::InOut;
        }
        return param;
    }
};

class LoadTargetArchitecture : public Inspector {
    ProgramStructure *structure;

 public:
    explicit LoadTargetArchitecture(ProgramStructure *structure) : structure(structure) {
        setName("LoadTargetArchitecture");
        CHECK_NULL(structure);
    }

    void setupMetadataRenameMap() {
        structure->addMetadata(INGRESS,
                               MetadataField{"standard_metadata", "egress_spec", 9},
                               MetadataField{"ig_intr_md_for_tm", "ucast_egress_port", 9});

        structure->addMetadata(EGRESS,
                               MetadataField{"standard_metadata", "egress_spec", 9},
                               MetadataField{"eg_intr_md", "egress_port", 9});

        structure->addMetadata(INGRESS,
                               MetadataField{"standard_metadata", "egress_port", 9},
                               MetadataField{"ig_intr_md_for_tm", "ucast_egress_port", 9});

        structure->addMetadata(EGRESS,
                               MetadataField{"standard_metadata", "egress_port", 9},
                               MetadataField{"eg_intr_md", "egress_port", 9});

        structure->addMetadata(MetadataField{"standard_metadata", "ingress_port", 9},
                               MetadataField{"ig_intr_md", "ingress_port", 9});

        structure->addMetadata(EGRESS,
                               MetadataField{"standard_metadata", "packet_length", 32},
                               MetadataField{"eg_intr_md", "pkt_length", 16});

        structure->addMetadata(MetadataField{"standard_metadata", "clone_spec", 32},
                               MetadataField{"compiler_generated_meta", "mirror_id", 10});

        structure->addMetadata(INGRESS,
                               MetadataField{"standard_metadata", "drop", 1},
                               MetadataField{"ig_intr_md_for_dprsr", "drop_ctl", 3});

        structure->addMetadata(INGRESS,
                               MetadataField{"standard_metadata", "drop", 1},
                               MetadataField{"eg_intr_md_for_dprsr", "drop_ctl", 3});

        structure->addMetadata(INGRESS,
                               MetadataField{"standard_metadata", "mcast_grp", 16},
                               MetadataField{"ig_intr_md_for_tm", "mcast_grp_a", 16});

        structure->addMetadata(INGRESS, MetadataField{"standard_metadata", "checksum_error", 1},
                               MetadataField{"ig_intr_md_from_prsr", "parser_err", 1, 12});

        structure->addMetadata(EGRESS, MetadataField{"standard_metadata", "checksum_error", 1},
                               MetadataField{"eg_intr_md_from_prsr", "parser_err", 1, 12});

        structure->addMetadata(MetadataField{"standard_metadata", "instance_type", 32},
                               MetadataField{"compiler_generated_meta", "instance_type", 32});

        structure->addMetadata(INGRESS,
                               MetadataField{"ig_intr_md_for_tm", "drop_ctl", 3},
                               MetadataField{"ig_intr_md_for_dprsr", "drop_ctl", 3});

        structure->addMetadata(EGRESS,
                               MetadataField{"eg_intr_md_for_oport", "drop_ctl", 3},
                               MetadataField{"eg_intr_md_for_dprsr", "drop_ctl", 3});

        structure->addMetadata(
                MetadataField{"ig_intr_md_from_parser_aux", "ingress_global_tstamp", 48},
                MetadataField{"ig_intr_md_from_prsr", "global_tstamp", 48});

        structure->addMetadata(MetadataField{"standard_metadata", "ingress_global_timestamp", 48},
                               MetadataField{"ig_intr_md_from_prsr", "global_tstamp", 48});

        structure->addMetadata(
                EGRESS,
                MetadataField{"eg_intr_md_from_parser_aux", "egress_global_tstamp", 48},
                MetadataField{"eg_intr_md_from_prsr", "global_tstamp", 48});

        structure->addMetadata(
                INGRESS,
                MetadataField{"ig_intr_md_from_parser_aux", "ingress_parser_err", 16},
                MetadataField{"ig_intr_md_from_prsr", "parser_err", 16});

        structure->addMetadata(
                EGRESS,
                MetadataField{"eg_intr_md_from_parser_aux", "egress_parser_err", 16},
                MetadataField{"eg_intr_md_from_prsr", "parser_err", 16});

        structure->addMetadata(
                EGRESS,
                MetadataField{"standard_metadata", "egress_global_timestamp", 48},
                MetadataField{"eg_intr_md_from_prsr", "global_tstamp", 48});

        structure->addMetadata(
                EGRESS,
                MetadataField{"standard_metadata", "enq_qdepth", 19},
                MetadataField{"eg_intr_md", "enq_qdepth", 19});

        structure->addMetadata(
                EGRESS,
                MetadataField{"standard_metadata", "enq_timestamp", 32},
                MetadataField{"eg_intr_md", "enq_tstamp", 18});

        structure->addMetadata(
                EGRESS,
                MetadataField{"standard_metadata", "deq_qdepth", 19},
                MetadataField{"eg_intr_md", "deq_qdepth", 19});

        structure->addMetadata(
                EGRESS,
                MetadataField{"eg_intr_md_from_parser_aux", "clone_src", 4},
                MetadataField{"compiler_generated_meta", "clone_src", 4});

        structure->addMetadata(
                EGRESS,
                MetadataField{"eg_intr_md_from_parser_aux", "clone_digest_id", 4},
                MetadataField{"compiler_generated_meta", "clone_digest_id", 4});

        structure->addMetadata(
                EGRESS,
                MetadataField{"standard_metadata", "egress_rid", 16},
                MetadataField{"eg_intr_md", "egress_rid", 16});
#ifdef HAVE_JBAY
        structure->addMetadata(INGRESS, MetadataField{"ig_intr_md_for_mb", "mirror_io_select", 1},
                               MetadataField{"ig_intr_md_for_dprsr", "mirror_io_select", 1});
        structure->addMetadata(EGRESS, MetadataField{"eg_intr_md_for_mb", "mirror_io_select", 1},
                               MetadataField{"eg_intr_md_for_dprsr", "mirror_io_select", 1});
        structure->addMetadata(INGRESS, MetadataField{"ig_intr_md_for_mb", "mirror_hash", 13},
                               MetadataField{"ig_intr_md_for_dprsr", "mirror_hash", 13});
        structure->addMetadata(EGRESS, MetadataField{"eg_intr_md_for_mb", "mirror_hash", 13},
                               MetadataField{"eg_intr_md_for_dprsr", "mirror_hash", 13});
        structure->addMetadata(INGRESS, MetadataField{"ig_intr_md_for_mb", "mirror_ingress_cos", 3},
                               MetadataField{"ig_intr_md_for_dprsr", "mirror_ingress_cos", 3});
        structure->addMetadata(EGRESS, MetadataField{"eg_intr_md_for_mb", "mirror_ingress_cos", 3},
                               MetadataField{"eg_intr_md_for_dprsr", "mirror_ingress_cos", 3});
        structure->addMetadata(INGRESS,
                               MetadataField{"ig_intr_md_for_mb", "mirror_deflect_on_drop", 1},
                               MetadataField{"ig_intr_md_for_dprsr", "mirror_deflect_on_drop", 1});
        structure->addMetadata(EGRESS,
                               MetadataField{"eg_intr_md_for_mb", "mirror_deflect_on_drop", 1},
                               MetadataField{"eg_intr_md_for_dprsr", "mirror_deflect_on_drop", 1});
        structure->addMetadata(INGRESS,
                               MetadataField{"ig_intr_md_for_mb", "mirror_copy_to_cpu_ctrl", 1},
                               MetadataField{"ig_intr_md_for_dprsr", "mirror_copy_to_cpu_ctrl", 1});
        structure->addMetadata(EGRESS,
                               MetadataField{"eg_intr_md_for_mb", "mirror_copy_to_cpu_ctrl", 1},
                               MetadataField{"eg_intr_md_for_dprsr", "mirror_copy_to_cpu_ctrl", 1});
        structure->addMetadata(INGRESS,
                               MetadataField{"ig_intr_md_for_mb", "mirror_copy_to_cpu_ctrl", 1},
                               MetadataField{"ig_intr_md_for_dprsr", "mirror_copy_to_cpu_ctrl", 1});
        structure->addMetadata(EGRESS,
                               MetadataField{"eg_intr_md_for_mb", "mirror_copy_to_cpu_ctrl", 1},
                               MetadataField{"eg_intr_md_for_dprsr", "mirror_copy_to_cpu_ctrl", 1});
        structure->addMetadata(INGRESS,
                               MetadataField{"ig_intr_md_for_mb", "mirror_multicast_ctrl", 1},
                               MetadataField{"ig_intr_md_for_dprsr", "mirror_multicast_ctrl", 1});
        structure->addMetadata(EGRESS,
                               MetadataField{"eg_intr_md_for_mb", "mirror_multicast_ctrl", 1},
                               MetadataField{"eg_intr_md_for_dprsr", "mirror_multicast_ctrl", 1});
        structure->addMetadata(INGRESS, MetadataField{"ig_intr_md_for_mb", "mirror_egress_port", 9},
                               MetadataField{"ig_intr_md_for_dprsr", "mirror_egress_port", 9});
        structure->addMetadata(EGRESS, MetadataField{"eg_intr_md_for_mb", "mirror_egress_port", 9},
                               MetadataField{"eg_intr_md_for_dprsr", "mirror_egress_port", 9});
        structure->addMetadata(INGRESS, MetadataField{"ig_intr_md_for_mb", "mirror_qid", 7},
                               MetadataField{"ig_intr_md_for_dprsr", "mirror_qid", 7});
        structure->addMetadata(EGRESS, MetadataField{"eg_intr_md_for_mb", "mirror_qid", 7},
                               MetadataField{"eg_intr_md_for_dprsr", "mirror_qid", 7});
        structure->addMetadata(INGRESS,
                               MetadataField{"ig_intr_md_for_mb", "mirror_coalesce_length", 8},
                               MetadataField{"ig_intr_md_for_dprsr", "mirror_coalesce_length", 8});
        structure->addMetadata(EGRESS,
                               MetadataField{"eg_intr_md_for_mb", "mirror_coalesce_length", 8},
                               MetadataField{"eg_intr_md_for_dprsr", "mirror_coalesce_length", 8});
#endif
    }

    void analyzeTofinoModel() {
        for (auto decl : structure->targetTypes) {
            if (auto v = decl->to<IR::Type_Enum>()) {
                structure->enums.emplace(v->name, v);
            } else if (auto v = decl->to<IR::Type_Error>()) {
                for (auto mem : v->members) {
                    structure->errors.emplace(mem->name);
                }
            }
        }
    }

    // XXX(hanw): Code to generate extra type declarations that we do not wish to publish yet.

    /* header pktgen_generic_header_t {
        bit<3> _pad0;
        bit<2> pipe_id;
        bit<3> app_id;
        bit<8> key_msb;
        bit<16> batch_id;
        bit<16> packet_id; } */
    const IR::Node* create_pktgen_generic_header_t() {
        auto fields = new IR::IndexedVector<IR::StructField>({
            new IR::StructField("_pad0", IR::Type_Bits::get(3)),
            new IR::StructField("pipe_id", IR::Type_Bits::get(2)),
            new IR::StructField("app_id", IR::Type_Bits::get(3)),
            new IR::StructField("key_msb", IR::Type_Bits::get(8)),
            new IR::StructField("batch_id", IR::Type_Bits::get(16)),
            new IR::StructField("packet_id", IR::Type_Bits::get(16))
        });
        return new IR::Type_Header("pktgen_generic_header_t", *fields);
    }

    /* extern selector_action {
        selector_action(ActionSelector sel);
        abstract void apply(inout bit<1> value, @optional out bit<1> rv);
        bit<1> execute(@optional in bit<32> index); } */
    const IR::Node* create_selector_action() {
        auto methods = new IR::Vector<IR::Method>({
            new IR::Method(
                "selector_action",
                new IR::Type_Method(
                new IR::ParameterList({
                    new IR::Parameter("sel", IR::Direction::None,
                        new IR::Type_Name("ActionSelector"))})), false),
            new IR::Method(
                "apply",
                new IR::Type_Method(
                new IR::Type_Void(),
                new IR::ParameterList({
                    new IR::Parameter("value", IR::Direction::InOut, IR::Type_Bits::get(1)),
                    new IR::Parameter("rv",
                        new IR::Annotations({new IR::Annotation(IR::ID("optional"), {})}),
                        IR::Direction::Out, IR::Type_Bits::get(1))})), true),
            new IR::Method(
                "execute",
                new IR::Type_Method(
                IR::Type_Bits::get(1),
                new IR::ParameterList({
                    new IR::Parameter("index",
                        new IR::Annotations({new IR::Annotation(IR::ID("optional"), {})}),
                        IR::Direction::In, IR::Type_Bits::get(32))})), false),
        });
        return new IR::Type_Extern("selector_action", *methods);
    }

    /* extern math_unit<T, U> {
        math_unit(bool invert, int<2> shift, int<6> scale, U data);
        T execute(in T x);
    } */
    const IR::Node* create_math_unit() {
        auto methods = new IR::Vector<IR::Method>({
            new IR::Method(
                "math_unit",
                new IR::Type_Method(
                new IR::ParameterList({
                    new IR::Parameter("invert", IR::Direction::None,
                        IR::Type_Boolean::get()),
                    new IR::Parameter("shift", IR::Direction::None,
                        IR::Type_Bits::get(2, true)),
                    new IR::Parameter("scale", IR::Direction::None,
                        IR::Type_Bits::get(6, true)),
                    new IR::Parameter("data", IR::Direction::None,
                        new IR::Type_Name("U"))})), false),
            new IR::Method(
                "execute",
                new IR::Type_Method(
                new IR::Type_Name("T"),
                new IR::ParameterList({
                    new IR::Parameter("x",
                        IR::Direction::In, new IR::Type_Name("T"))})), false),
        });
        auto typeVars = new IR::IndexedVector<IR::Type_Var>({
            new IR::Type_Var("T"), new IR::Type_Var("U")
        });
        auto typeParams = new IR::TypeParameters(*typeVars);
        return new IR::Type_Extern("math_unit", typeParams, *methods);
    }

    void postorder(const IR::P4Program *) override {
        setupMetadataRenameMap();

        /// append device specific architecture definition

        // CODE_HACK
        // we are concatenating all the include files that define an architecture
        // because the current parsing does not take context into account, and thus
        // we can't safely separate metadata definitions (which are device specific)
        // from control block definitions (which are not device specific).
        char * drvP4IncludePath = getenv("P4C_16_INCLUDE_PATH");
        Util::PathName path(drvP4IncludePath ? drvP4IncludePath : p4includePath);
        char tempPath[PATH_MAX];
        snprintf(tempPath, PATH_MAX-1, "/tmp/arch_XXXXXX.p4");
        std::vector<const char *>filenames;
        if (Device::currentDevice() == Device::TOFINO)
            filenames.push_back("tofino.p4");
#if HAVE_JBAY
        else
            filenames.push_back("tofino2.p4");
#endif  // HAVE_JBAY
        filenames.push_back("tofino/stratum.p4");
        filenames.push_back("tofino/p4_14_prim.p4");

        // create a temporary file. The safe method is to create and open the file
        // in exclusive mode. Since we can only open a C++ stream with a hack, we'll close
        // the file and then open it again as an ofstream.
        auto fd = mkstemps(tempPath, 3);
        if (fd < 0) {
            ::error("Error mkstemp(%1%): %2%", tempPath, strerror(errno));
            return;
        }
        // close the file descriptor and open as stream
        close(fd);
        std::ofstream result(tempPath, std::ios::out);
        if (!result.is_open()) {
            ::error("Failed to open arch include file %1%", tempPath);
            return;
        }
        for (auto f : filenames) {
            Util::PathName fPath = path.join(f);
            std::ifstream inFile(fPath.toString(), std::ios::in);
            if (inFile.is_open()) {
                result << inFile.rdbuf();
                inFile.close();
            } else {
                ::error("Failed to open architecture include file %1%", fPath.toString());
                result.close();
                unlink(tempPath);
                return;
            }
        }
        result.close();
        structure->include(tempPath, &structure->targetTypes);
        unlink(tempPath);

        // XXX(hanw): add extra type declaration that are not ready to publish
        structure->targetTypes.push_back(create_pktgen_generic_header_t());
        structure->targetTypes.push_back(create_selector_action());
        structure->targetTypes.push_back(create_math_unit());

        analyzeTofinoModel();

        if (structure->backward_compatible)
            structure->targetTypes = *(structure->targetTypes.apply(FixupBackwardCompatibility()));
    }
};

//////////////////////////////////////////////////////////////////////////////////////////////

class RemoveNodesWithNoMapping : public Transform {
    // following fields are showing up in struct H, because in P4-14
    // these structs are declared as header type.
    // In TNA, most of these metadata are individual parameter to
    // the control block, and shall be removed from struct H.
    std::set<cstring> removeAllOccurences = {
            "generator_metadata_t_0",
            "ingress_parser_control_signals",
            "standard_metadata_t",
            "egress_intrinsic_metadata_t",
            "egress_intrinsic_metadata_for_mirror_buffer_t",
            "egress_intrinsic_metadata_for_output_port_t",
            "egress_intrinsic_metadata_from_parser_aux_t",
            "ingress_intrinsic_metadata_t",
            "ingress_intrinsic_metadata_for_mirror_buffer_t",
            "ingress_intrinsic_metadata_for_tm_t",
            "ingress_intrinsic_metadata_from_parser_aux_t"};

    std::set<cstring> removeDeclarations = {
            "pktgen_generic_header_t",
            "pktgen_port_down_header_t",
            "pktgen_recirc_header_t",
            "pktgen_timer_header_t"};

 public:
    RemoveNodesWithNoMapping() { setName("RemoveNodesWithNoMapping"); }

    const IR::Node *preorder(IR::Type_Header *node) {
        auto it = removeAllOccurences.find(node->name);
        if (it != removeAllOccurences.end())
            return nullptr;
        it = removeDeclarations.find(node->name);
        if (it != removeDeclarations.end())
            return nullptr;
        return node;
    }

    const IR::Node *preorder(IR::Type_Struct *node) {
        auto it = removeAllOccurences.find(node->name);
        if (it != removeAllOccurences.end())
            return nullptr;
        it = removeDeclarations.find(node->name);
        if (it != removeDeclarations.end())
            return nullptr;
        return node;
    }

    const IR::Node *preorder(IR::StructField *node) {
        auto header = findContext<IR::Type_Struct>();
        if (!header) return node;
        if (header->name != "headers") return node;

        auto type = node->type->to<IR::Type_Name>();
        if (!type) return node;

        auto it = removeAllOccurences.find(type->path->name);
        if (it != removeAllOccurences.end())
            return nullptr;
        return node;
    }

    /// Given a IR::Member of the following structure:
    ///
    /// Member member=mcast_grp_b
    ///   type: Type_Bits size=16 isSigned=0
    ///   expr: Member member=ig_intr_md_for_tm
    ///     type: Type_Header name=ingress_intrinsic_metadata_for_tm_t
    ///     expr: PathExpression
    ///       type: Type_Name...
    ///       path: Path name=hdr absolute=0
    ///
    /// transform it to the following:
    ///
    /// Member member=mcast_grp_b
    ///   type: Type_Bits size=16 isSigned=0
    ///   expr: PathExpression
    ///     type: Type_Name...
    ///     path: Path name=ig_intr_md_for_tm
    const IR::Node *preorder(IR::Member *mem) {
        auto submem = mem->expr->to<IR::Member>();
        if (!submem) return mem;
        auto submemType = submem->type->to<IR::Type_Header>();
        if (!submemType) return mem;
        auto it = removeAllOccurences.find(submemType->name);
        if (it == removeAllOccurences.end()) return mem;

        auto newType = new IR::Type_Name(submemType->name);
        auto newName = new IR::Path(submem->member);
        auto newExpr = new IR::PathExpression(newType, newName);
        auto newMem = new IR::Member(mem->srcInfo, mem->type, newExpr, mem->member);
        return newMem;
    }
};

//////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////

/// @pre: assume no nested control block or parser block,
///       as a result, all declarations within a control block have different names.
/// @post: all user provided names for metadata are converted to standard names
///       assumed by the translation map in latter pass.
class NormalizeProgram : public Transform {
    ordered_map<cstring, std::vector<const IR::Node *> *> namescopes;
    ordered_map<cstring, cstring> renameMap;
    ordered_map<cstring, cstring> aliasMap;

 public:
    NormalizeProgram() {}

    void pushParam(const IR::Node *node, cstring param_type, cstring rename) {
        const IR::ParameterList *list;
        if (auto ctrl = node->to<IR::P4Control>()) {
            list = ctrl->type->getApplyParameters();
        } else if (auto parser = node->to<IR::P4Parser>()) {
            list = parser->type->getApplyParameters();
        } else {
            BUG("Unknown block type %1%", node);
        }

        for (auto p : list->parameters) {
            if (!p->type->is<IR::Type_Name>())
                continue;
            auto type_name = p->type->to<IR::Type_Name>();
            auto type = type_name->path->name;
            if (type != param_type)
                continue;
            auto name = p->name;
            auto it = namescopes.find(name);
            if (it == namescopes.end()) {
                auto stack = new std::vector<const IR::Node *>();
                stack->push_back(getOriginal<IR::Node>());
                namescopes.emplace(name, stack);
                renameMap.emplace(name, rename);
            } else {
                auto &stack = it->second;
                stack->push_back(getOriginal<IR::Node>());
            }
        }
    }

    void popParam(const IR::Node *node, cstring param_type) {
        const IR::ParameterList *list = nullptr;
        if (auto ctrl = node->to<IR::P4Control>()) {
            list = ctrl->type->getApplyParameters();
        } else if (auto parser = node->to<IR::P4Parser>()) {
            list = parser->type->getApplyParameters();
        }
        CHECK_NULL(list);

        for (auto p : list->parameters) {
            if (!p->type->is<IR::Type_Name>())
                continue;
            auto type_name = p->type->to<IR::Type_Name>();
            auto type = type_name->path->name;
            if (type != param_type)
                continue;
            auto name = p->name;
            auto it = namescopes.find(name);
            if (it != namescopes.end()) {
                auto &stack = it->second;
                BUG_CHECK(stack->size() >= 1, "Cannot pop empty stack");
                stack->pop_back();
            }
        }
    }

    const IR::Node *preorder(IR::P4Control *node) override {
        pushParam(node, "standard_metadata_t", "standard_metadata");
        return node;
    }

    const IR::Node *postorder(IR::P4Control *node) override {
        popParam(node, "standard_metadata_t");
        return node;
    }

    const IR::Node *preorder(IR::P4Parser *node) override {
        pushParam(node, "standard_metadata_t", "standard_metadata");
        return node;
    }

    const IR::Node *postorder(IR::P4Parser *node) override {
        popParam(node, "standard_metadata_t");
        return node;
    }

    const IR::Node *preorder(IR::Declaration_Variable *node) override {
        auto name = node->name.name;
        auto it = namescopes.find(name);
        if (it != namescopes.end()) {
            auto &stack = it->second;
            stack->push_back(node->to<IR::Node>());
        }
        return node;
    }

    const IR::Node *postorder(IR::Declaration_Variable *node) override {
        auto name = node->name.name;
        auto it = namescopes.find(name);
        if (it != namescopes.end()) {
            auto &stack = it->second;
            stack->pop_back();
        }
        return node;
    }

    const IR::Node *postorder(IR::PathExpression *node) override {
        auto path = node->path->name;
        auto it = namescopes.find(path);
        if (it != namescopes.end()) {
            auto renameIt = renameMap.find(path);
            if (renameIt != renameMap.end()) {
                return new IR::PathExpression(node->srcInfo, node->type,
                                              new IR::Path(renameIt->second));
            }
        }
        return node;
    }

    const IR::Node *postorder(IR::Parameter *node) override {
        auto it = namescopes.find(node->name);
        if (it != namescopes.end()) {
            auto renameIt = renameMap.find(node->name);
            if (renameIt != renameMap.end()) {
                auto rename = renameIt->second;
                return new IR::Parameter(node->srcInfo, rename, node->annotations,
                                         node->direction, node->type);
            }
        }
        return node;
    }

    /// recursively check if a fromName is aliased to toName
    bool isStandardMetadata(cstring fromName) {
        auto it = aliasMap.find(fromName);
        if (it != aliasMap.end()) {
            auto toName_ = it->second;
            if (isStandardMetadata(toName_))
                return true;
            else if (toName_ == "standard_metadata_t")
                return true;
            else
                return false;
        } else {
            return false;
        }
    }

    const IR::Node *preorder(IR::Type_Typedef *node) override {
        if (auto name = node->type->to<IR::Type_Name>()) {
            aliasMap.emplace(node->name, name->path->name);    // std_meta_t -> standard_metadata_t
        }
        return node;
    }

    const IR::Node *postorder(IR::Type_Typedef *node) override {
        if (isStandardMetadata(node->name)) {
            return nullptr;
        }
        return node;
    }

    const IR::Node *postorder(IR::Type_Name *node) override {
        if (isStandardMetadata(node->path->name)) {
            return new IR::Type_Name(node->srcInfo, new IR::Path("standard_metadata_t"));
        }
        return node;
    }
};

//////////////////////////////////////////////////////////////////////////////////////////////

/// This pass collects all top level p4program declarations.
class AnalyzeProgram : public Inspector {
    ProgramStructure *structure;

    template<class P4Type, class BlockType>
    void analyzeArchBlock(const IR::ToplevelBlock *blk, cstring name, cstring type) {
        auto main = blk->getMain();
        auto ctrl = main->findParameterValue(name);
        ERROR_CHECK(ctrl != nullptr, "%1%: could not find parameter %2%", main, name);
        ERROR_CHECK(ctrl->is<BlockType>(), "%1%: main package match the expected model", main);
        auto block = ctrl->to<BlockType>()->container;
        BUG_CHECK(block != nullptr, "Unable to find %1% block in V1Switch", name);
        structure->blockNames.emplace(type, block->name);
    }

 public:
    explicit AnalyzeProgram(ProgramStructure *structure)
            : structure(structure) {
        CHECK_NULL(structure);
        setName("AnalyzeProgram");
    }

    // *** architectural declarations ***
    // matchKindDeclaration
    // constantDeclarations
    // externDeclarations
    // parserDeclarations
    // controlDeclarations
    // *** program & architectural declarations ***
    // actionDeclarations
    void postorder(const IR::Type_Action *node) override {
        structure->action_types.push_back(node);
    }

    // errorDeclaration
    void postorder(const IR::Type_Error *node) override {
        for (auto m : node->members) {
            structure->errors.emplace(m->name);
        }
    }

    // typeDeclarations
    void postorder(const IR::Type_StructLike *node) override {
        structure->type_declarations.emplace(node->name, node);
    }

    void postorder(const IR::Type_Typedef *node) override {
        structure->type_declarations.emplace(node->name, node);
    }

    void postorder(const IR::Type_Enum *node) override {
        structure->enums.emplace(node->name, node);
    }

    // *** program only declarations ***
    // instantiation - parser
    void postorder(const IR::P4Parser *node) override {
        structure->parsers.emplace(node->name, node);
        // additional info for translation
        auto params = node->getApplyParameters();
        if (params->parameters.size() >= 2) {
            structure->user_metadata = node->type->applyParams->parameters.at(2);
        } else {
            ::error("Parser in v1model must have at least 2 parameters");
        }
    }

    // instantiation - control
    void postorder(const IR::P4Control *node) override {
        structure->controls.emplace(node->name, node);
    }

    // instantiation - extern
    void postorder(const IR::Declaration_Instance *node) override {
        // look for global instances
        auto control = findContext<IR::P4Control>();
        if (control) return;
        auto parser = findContext<IR::P4Parser>();
        if (parser) return;
        // ignore main()
        if (auto type = node->type->to<IR::Type_Specialized>()) {
            auto typeName = type->baseType->to<IR::Type_Name>();
            if (typeName && typeName->path->name == "V1Switch")
                return;
        }
        structure->global_instances.emplace(node->name, node);
    }

    // instantiation - program
    void postorder(const IR::P4Program *) override {
        auto params = structure->toplevel->getMain()->getConstructorParameters();
        if (params->parameters.size() != 6) {
            std::stringstream msg;
            msg << "Expecting 6 parameters instead of " << params->parameters.size()
                << " in the 'main' instance." << std::endl;
            msg << "Did you specify the correct architecture using --arch?";

            ::error("%1%", msg.str());
            return;
        }
        analyzeArchBlock<IR::P4Parser, IR::ParserBlock>(
                structure->toplevel, "p", ProgramStructure::INGRESS_PARSER);
        analyzeArchBlock<IR::P4Parser, IR::ParserBlock>(
                structure->toplevel, "p", ProgramStructure::EGRESS_PARSER);
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(
                structure->toplevel, "ig", ProgramStructure::INGRESS);
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(
                structure->toplevel, "eg", ProgramStructure::EGRESS);
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(
                structure->toplevel, "dep", ProgramStructure::INGRESS_DEPARSER);
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(
                structure->toplevel, "dep", ProgramStructure::EGRESS_DEPARSER);
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(
                structure->toplevel, "vr", "verifyChecksum");
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(
                structure->toplevel, "ck", "updateChecksum");
    }

    void end_apply() override {
        // add 'compiler_generated_metadata_t'
        auto cgm = new IR::Type_Struct("compiler_generated_metadata_t");

        // Inject new fields for mirroring.
        cgm->fields.push_back(
            new IR::StructField("mirror_id", IR::Type::Bits::get(10)));
        cgm->fields.push_back(
            new IR::StructField("mirror_source", IR::Type::Bits::get(8)));
        // XXX(hanw): we can probably remove these two fields.
        cgm->fields.push_back(
            new IR::StructField("clone_src", IR::Type::Bits::get(4)));
        cgm->fields.push_back(
            new IR::StructField("clone_digest_id", IR::Type::Bits::get(4)));
        // Used to support separate egress_start parser state.
        cgm->fields.push_back(
            new IR::StructField("instance_type", IR::Type::Bits::get(32)));

        structure->type_declarations.emplace("compiler_generated_metadata_t", cgm);

        // Add an instance of parser counter
        {
            auto typeArgs = new IR::Vector<IR::Type>({IR::Type::Bits::get(8)});
            auto type = new IR::Type_Specialized(
                new IR::Type_Name("ParserCounter"), typeArgs);
            auto decl = new IR::Declaration_Instance(
                "ig_prsr_ctrl_parser_counter", type,
                new IR::Vector<IR::Argument>());
            structure->ingressParserDeclarations.push_back(decl);
            structure->egressParserDeclarations.push_back(decl);
        }

        // Add an instance of parser priority
        {
            auto type = new IR::Type_Name("ParserPriority");
            auto decl = new IR::Declaration_Instance(
                "ig_prsr_ctrl_priority", type, new IR::Vector<IR::Argument>());
            structure->ingressParserDeclarations.push_back(decl);
            structure->egressParserDeclarations.push_back(decl);
        }
    }
};

//////////////////////////////////////////////////////////////////////////////////////////////

bool analyzeChecksumCall(const IR::MethodCallStatement *statement, cstring which) {
    auto methodCall = statement->methodCall->to<IR::MethodCallExpression>();
    if (!methodCall) {
        ::warning("Expected a non-empty method call expression: %1%", statement);
        return false;
    }
    auto method = methodCall->method->to<IR::PathExpression>();
    if (!method || (method->path->name != which)) {
        ::warning("Expected an %1% statement in %2%", statement, which);
        return false;
    }
    if (methodCall->arguments->size() != 4) {
        ::warning("Expected 4 arguments for %1% statement: %2%", statement, which);
        return false;
    }

    auto destField = (*methodCall->arguments)[2]->expression->to<IR::Member>();
    CHECK_NULL(destField);

    auto condition = (*methodCall->arguments)[0]->expression;
    CHECK_NULL(condition);

    bool nominalCondition = false;
    if (auto mc = condition->to<IR::MethodCallExpression>()) {
        if (auto m = mc->method->to<IR::Member>()) {
            if (m->member == "isValid") {
                if (m->expr->equiv(*(destField->expr))) {
                    nominalCondition = true; } } } }

    auto bl = condition->to<IR::BoolLiteral>();
    if (which == "verify_checksum" && !nominalCondition && (!bl || bl->value != true))
        ::error("Tofino does not support conditional checksum verification: %1%", destField);

    auto algorithm = (*methodCall->arguments)[3]->expression->to<IR::Member>();
    if (!algorithm || algorithm->member != "csum16")
        ::error("Tofino only supports \"csum16\" for checksum calculation: %1%", destField);

    return true;
}

static IR::Declaration_Instance*
createChecksumDeclaration(ProgramStructure *structure,
                          const IR::MethodCallStatement* csum) {
    auto mc = csum->methodCall->to<IR::MethodCallExpression>();

    auto typeArgs = new IR::Vector<IR::Type>();
    typeArgs->push_back(mc->arguments->at(2)->expression->type);
    auto inst = new IR::Type_Specialized(new IR::Type_Name("Checksum"), typeArgs);

    auto csum_name = cstring::make_unique(structure->unique_names, "checksum", '_');
    structure->unique_names.insert(csum_name);
    auto args = new IR::Vector<IR::Argument>();
    auto hashAlgo = new IR::Member(
            new IR::TypeNameExpression("HashAlgorithm_t"), "CSUM16");
    args->push_back(new IR::Argument(hashAlgo));
    auto decl = new IR::Declaration_Instance(csum_name, inst, args);

    return decl;
}

static IR::AssignmentStatement*
createChecksumError(const IR::Declaration* decl, gress_t gress) {
     auto methodCall = new IR::Member(new IR::PathExpression(decl->name), "verify");
     auto verifyCall = new IR::MethodCallExpression(methodCall, {});
     auto rhs = new IR::Cast(IR::Type::Bits::get(1), verifyCall);

     cstring intr_md;

     if (gress == INGRESS)
         intr_md = "ig_intr_md_from_prsr";
     else if (gress == EGRESS)
         intr_md = "eg_intr_md_from_prsr";
     else
         BUG("Unhandled gress: %1%.", gress);

     auto parser_err = new IR::Member(
         new IR::PathExpression(intr_md), "parser_err");

     auto lhs = new IR::Slice(parser_err, 12, 12);
     return new IR::AssignmentStatement(lhs, rhs);
}

static std::vector<gress_t>
getChecksumUpdateLocations(const IR::BlockStatement* block, cstring pragma) {
    std::vector<gress_t> updateLocations;

    if (pragma == "calculated_field_update_location")
        updateLocations = { EGRESS };
    else if (pragma == "residual_checksum_parser_update_location")
        updateLocations = { INGRESS };
    else
        BUG("Invalid use of function getChecksumUpdateLocation");

    for (auto annot : block->annotations->annotations) {
        if (annot->name.name == pragma) {
            auto& exprs = annot->expr;
            auto gress = exprs[0]->to<IR::StringLiteral>();

            if (gress->value == "ingress")
                updateLocations = { INGRESS };
            else if (gress->value == "egress")
                updateLocations = { EGRESS };
            else if (gress->value == "ingress_and_egress")
                updateLocations = { INGRESS, EGRESS };
            else
                BUG("Invalid use of @pragma %1%, valid value "
                    " is ingress/egress/ingress_and_egress", pragma);
        }
    }

    return updateLocations;
}

class ConstructSymbolTable : public Inspector {
    ProgramStructure *structure;
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;
    const V1::TranslateParserChecksums* parserChecksums;
    // cloneIndex assignment algorithm:
    // - we assign a unique index per field list per gress
    // - there could be multiple actions calling clone within a table
    // - for a gress, a map of hashes is generated for a field list string
    // - the clone index is the value stored for hash key of element within the
    // map
    std::map<unsigned long, unsigned> cloneIndexHashes[2];
    // resubmitIndex assignment algorithm:
    // - we assign a unique index per resubmit field list
    // - there could be multiple actions calling resubmit within a table
    // - can only be called in one gress
    // - a map of hashes is generated for a field list string
    // - the resubmit index is the value stored for hash key of element within
    // the map
    std::map<unsigned long, unsigned> resubmitIndexHashes;
    // digestIndex is similar to resubmitIndex and generate_digest() can only be called in ingress
    std::map<unsigned long, unsigned> digestIndexHashes;

    std::set<cstring> globals;

 public:
    ConstructSymbolTable(ProgramStructure *structure,
                         P4::ReferenceMap *refMap, P4::TypeMap *typeMap,
                         const V1::TranslateParserChecksums* parserChecksums)
            : structure(structure), refMap(refMap), typeMap(typeMap),
              parserChecksums(parserChecksums) {
        CHECK_NULL(structure);
        setName("ConstructSymbolTable");
    }

    /*
     * following extern methods in v1model.p4 need to be converted to an extern instance
     * and a method call on the instance.
     * random, digest, mark_to_drop, hash, verify_checksum, update_checksum, resubmit
     * recirculate, clone, clone3, truncate
     */
    void cvtDigestFunction(const IR::MethodCallStatement *node) {
        /*
         * translate digest() function in ingress control block to
         *
         * ig_intr_md_for_dprsr.digest_type = n;
         *
         */
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(mce != nullptr, "malformed IR in digest() function");
        auto control = findContext<IR::P4Control>();
        ERROR_CHECK(control != nullptr, "digest() must be used in a control block");
        ERROR_CHECK(control->name == structure->getBlockName(ProgramStructure::INGRESS),
                  "digest() can only be used in %1%",
                  structure->getBlockName(ProgramStructure::INGRESS));
        IR::PathExpression *path = new IR::PathExpression("ig_intr_md_for_dprsr");
        auto mem = new IR::Member(path, "digest_type");
        unsigned digestId = getIndex(node, digestIndexHashes);
        if (digestId > Device::maxDigestId()) {
            ::error("Too many digest() calls in %1%", control->name);
            return;
        }
        unsigned bits = static_cast<unsigned>(std::ceil(std::log2(Device::maxDigestId())));
        auto idx = new IR::Constant(IR::Type::Bits::get(bits), digestId);
        auto stmt = new IR::AssignmentStatement(mem, idx);
        structure->_map.emplace(node, stmt);

        ERROR_CHECK(mce->typeArguments->size() == 1, "Expected 1 type parameter for %1%",
                  mce->method);
        auto *typeArg = mce->typeArguments->at(0);
        auto *typeName = typeArg->to<IR::Type_Name>();
        ERROR_CHECK(typeName != nullptr, "Expected type T in digest to be a typeName %1%", typeArg);
        auto fieldList = refMap->getDeclaration(typeName->path);
        auto declAnno = fieldList->getAnnotation("name");

        ERROR_CHECK(typeName != nullptr, "Wrong argument type for %1%", typeArg);
        /*
         * In the ingress deparser, add the following code
         * Digest<T>() learn_1;
         * if (ig_intr_md_for_dprsr.digest_type == n)
         *    learn_1.pack({fields});
         *
         */
        auto field_list = mce->arguments->at(1);
        auto args = new IR::Vector<IR::Argument>({field_list});
        auto expr = new IR::PathExpression(new IR::Path(typeName->path->name));
        auto member = new IR::Member(expr, "pack");
        auto typeArgs = new IR::Vector<IR::Type>();
        auto mcs = new IR::MethodCallStatement(
                new IR::MethodCallExpression(member, typeArgs, args));

        auto condExprPath = new IR::Member(
                new IR::PathExpression(new IR::Path("ig_intr_md_for_dprsr")), "digest_type");
        auto condExpr = new IR::Equ(condExprPath, idx);
        auto cond = new IR::IfStatement(condExpr, mcs, nullptr);
        structure->ingressDeparserStatements.push_back(cond);

        auto declArgs = new IR::Vector<IR::Argument>({});
        auto declType = new IR::Type_Specialized(new IR::Type_Name("Digest"), mce->typeArguments);
        auto annotations = declAnno ? new IR::Annotations({declAnno}) : new IR::Annotations();
        auto decl = new IR::Declaration_Instance(typeName->path->name, annotations,
                                                 declType, declArgs);
        structure->ingressDeparserDeclarations.push_back(decl);
    }

    /**
     * invalidate_digest
     *
     * translate the invalid_digest() call in ingress control block to
     * invalidate(ig_intr_md_for_dprsr.digest_type)
     *
     */
    void cvtInvalidateDigestFunction(const IR::MethodCallStatement *node) {
        /*
         * \TODO: Check that generate_digest has been called before
         */
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(mce != nullptr, "malformed IR in digest() function");
        auto control = findContext<IR::P4Control>();
        ERROR_CHECK(control != nullptr, "digest() must be used in a control block");
        ERROR_CHECK(control->name == structure->getBlockName(ProgramStructure::INGRESS),
                  "digest() can only be used in %1%",
                  structure->getBlockName(ProgramStructure::INGRESS));
        IR::PathExpression *path = new IR::PathExpression("ig_intr_md_for_dprsr");
        auto mem = new IR::Member(path, "digest_type");
        auto stmt = new IR::MethodCallStatement(node->srcInfo, IR::ID(node->srcInfo, "invalidate"),
                                                { new IR::Argument(mem) } );
        structure->_map.emplace(node, stmt);
    }

    void cvtCloneFunction(const IR::MethodCallStatement *node, bool hasData) {
        LOG1("cvtCloneFunction: (id= " << node->id << " ) " << node);
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(mce != nullptr, "malformed IR in clone() function");
        auto control = findContext<IR::P4Control>();
        ERROR_CHECK(control != nullptr, "clone() must be used in a control block");

        const bool isIngress =
                (control->name == structure->getBlockName(ProgramStructure::INGRESS));
        const gress_t gress = isIngress? INGRESS : EGRESS;
        auto *deparserMetadataPath =
                new IR::PathExpression(isIngress ? "ig_intr_md_for_dprsr"
                                                 : "eg_intr_md_for_dprsr");
        auto *compilerMetadataPath =
                new IR::PathExpression("compiler_generated_meta");

        // Generate a fresh index for this clone field list. This is used by the
        // hardware to select the correct mirror table entry, and to select the
        // correct parser for this field list.
        unsigned cloneId = getIndex(node, cloneIndexHashes[gress]);

        // COMPILER-914: In Tofino, Disable clone id - 0 which is reserved in
        // i2e due to a hardware bug. Hence, valid clone ids are 1 - 7.  All
        // clone id's 0 - 7 are valid for e2e
        if ((Device::currentDevice() == Device::TOFINO) && (gress == INGRESS)) {
            cloneId++;
        }

        unsigned bits = static_cast<unsigned>(std::ceil(std::log2(Device::maxCloneId(gress))));
        auto *idx = new IR::Constant(IR::Type::Bits::get(bits), cloneId);

        {
            auto *block = new IR::BlockStatement;

            // Construct a value for `mirror_source`, which is
            // compiler-generated metadata that's prepended to the user field
            // list. Its layout (in network order) is:
            //   [  0    1       2          3         4       5    6   7 ]
            //     [unused] [coalesced?] [gress] [mirrored?] [mirror_type]
            // Here `gress` is 0 for I2E mirroring and 1 for E2E mirroring.
            //
            // This information is used to set intrinsic metadata in the egress
            // parser. The `mirrored?` bit is particularly important; if that
            // bit is zero, the egress parser expects the following bytes to be
            // bridged metadata rather than mirrored fields.
            //
            // XXX(seth): Glass is able to reuse `mirror_type` for last three
            // bits of this data, which eliminates the need for an extra PHV
            // container. We'll start doing that soon as well, but we need to
            // work out some issues with PHV allocation constraints first.
            auto *mirrorSource = new IR::Member(compilerMetadataPath, "mirror_source");
            const unsigned sourceIdx = idx->asInt();
            const unsigned isMirroredTag = 1 << 3;
            const unsigned gressTag = isIngress ? 0 : 1 << 4;
            auto *source =
                    new IR::Constant(IR::Type::Bits::get(8), sourceIdx | isMirroredTag | gressTag);
            block->components.push_back(new IR::AssignmentStatement(mirrorSource, source));

            // Set `mirror_type`, which is used as the digest selector in the
            // deparser (in other words, it selects the field list to use).
            auto *mirrorIdx = new IR::Member(deparserMetadataPath, "mirror_type");
            block->components.push_back(new IR::AssignmentStatement(mirrorIdx, idx));

            // Set `mirror_id`, which configures the mirror session id that the
            // hardware uses to route mirrored packets in the TM.
            ERROR_CHECK(mce->arguments->size() >= 2,
                      "No mirror session id specified: %1%", mce);
            auto *mirrorId = new IR::Member(compilerMetadataPath, "mirror_id");
            auto *mirrorIdValue = mce->arguments->at(1)->expression;
            /// v1model mirror_id is 32bit, cast to bit<10>
            auto *castedMirrorIdValue = new IR::Cast(IR::Type::Bits::get(10), mirrorIdValue);
            block->components.push_back(new IR::AssignmentStatement(mirrorId,
                                                                    castedMirrorIdValue));
            structure->_map.emplace(node, block);
        }

        /*
         * generate statement in ingress/egress deparser to prepend mirror metadata
         *
         * Mirror mirror();
         * if (ig_intr_md_for_dprsr.mirror_type == N)
         *    mirror.emit({});
         */

        // Only instantiate the extern for the first instance of clone()
        auto findDecl = [](std::vector<const IR::Declaration*> decls,
                           cstring name) -> const IR::Declaration * {
            for (auto d : decls)
                if (d->getName() == name) return d;
            return nullptr;
        };
        const IR::Declaration* mirrorDeclared = isIngress ?
            findDecl(structure->ingressDeparserDeclarations, "mirror") :
            findDecl(structure->egressDeparserDeclarations, "mirror");

        if (mirrorDeclared == nullptr) {
            auto declArgs = new IR::Vector<IR::Argument>({});
            auto declType = new IR::Type_Name("Mirror");
            auto decl = new IR::Declaration_Instance("mirror", declType, declArgs);
            if (isIngress)
                structure->ingressDeparserDeclarations.push_back(decl);
            else
                structure->egressDeparserDeclarations.push_back(decl);
        }

        auto *newFieldList = new IR::ListExpression({
            new IR::Member(compilerMetadataPath, "mirror_source")});

        if (hasData && mce->arguments->size() > 2) {
            auto *clonedData = mce->arguments->at(2)->expression;
            if (auto *originalFieldList = clonedData->to<IR::ListExpression>())
                newFieldList->components.pushBackOrAppend(&originalFieldList->components);
            else
                newFieldList->components.push_back(clonedData);
        }

        auto args = new IR::Vector<IR::Argument>();
        args->push_back(new IR::Argument(new IR::Member(compilerMetadataPath, "mirror_id")));
        args->push_back(new IR::Argument(newFieldList));

        auto pathExpr = new IR::PathExpression(new IR::Path("mirror"));
        auto member = new IR::Member(pathExpr, "emit");
        auto typeArgs = new IR::Vector<IR::Type>();
        auto mcs = new IR::MethodCallStatement(
                new IR::MethodCallExpression(member, typeArgs, args));
        auto condExprPath = new IR::Member(deparserMetadataPath, "mirror_type");
        auto condExpr = new IR::Equ(condExprPath, idx);
        auto cond = new IR::IfStatement(condExpr, mcs, nullptr);
        if (isIngress)
            structure->ingressDeparserStatements.push_back(cond);
        else
            structure->egressDeparserStatements.push_back(cond);
    }

    void cvtDropFunction(const IR::MethodCallStatement *node) {
        auto control = findContext<IR::P4Control>();
        if (control->name == structure->getBlockName(ProgramStructure::INGRESS)) {
            auto path = new IR::Member(
                    new IR::PathExpression("ig_intr_md_for_dprsr"), "drop_ctl");
            auto val = new IR::Constant(IR::Type::Bits::get(3), 1);
            auto stmt = new IR::AssignmentStatement(path, val);
            structure->_map.emplace(node, stmt);
        } else if (control->name == structure->getBlockName(ProgramStructure::EGRESS)) {
            auto path = new IR::Member(
                    new IR::PathExpression("eg_intr_md_for_dprsr"), "drop_ctl");
            auto val = new IR::Constant(IR::Type::Bits::get(3), 1);
            auto stmt = new IR::AssignmentStatement(path, val);
            structure->_map.emplace(node, stmt);
        }
    }

    /// execute_meter_with_color is converted to a meter extern
    void cvtExecuteMeterFunctiion(const IR::MethodCallStatement *node) {
        auto control = findContext<IR::P4Control>();
        ERROR_CHECK(control != nullptr,
                  "execute_meter_with_color() must be used in a control block");
        auto mce = node->methodCall->to<IR::MethodCallExpression>();

        auto inst = mce->arguments->at(0)->expression->to<IR::PathExpression>();
        BUG_CHECK(inst != nullptr, "Invalid meter instance %1%", inst);
        auto path = inst->to<IR::PathExpression>()->path;
        auto pathExpr = new IR::PathExpression(path->name);

        auto method = new IR::Member(node->srcInfo, pathExpr, "execute");
        auto args = new IR::Vector<IR::Argument>();
        args->push_back(mce->arguments->at(1));
        args->push_back(new IR::Argument(
            new IR::Cast(IR::Type::Bits::get(2), mce->arguments->at(3)->expression)));
        auto methodCall = new IR::MethodCallExpression(node->srcInfo, method, args);

        auto meterColor = mce->arguments->at(2)->expression;
        auto size = meterColor->type->width_bits();
        IR::AssignmentStatement *assign = nullptr;
        if (size > 8) {
            assign = new IR::AssignmentStatement(
                    meterColor, new IR::Cast(IR::Type::Bits::get(size), methodCall));
        } else if (size < 8) {
            assign = new IR::AssignmentStatement(meterColor,
                                                 new IR::Slice(methodCall, size - 1, 0));
        } else {
            assign = new IR::AssignmentStatement(meterColor, methodCall);
        }
        structure->_map.emplace(node, assign);
    }

    void convertHashPrimitive(const IR::MethodCallStatement *node, cstring hashName) {
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        ERROR_CHECK(mce->arguments->size() > 4, "insufficient arguments to hash() function");
        auto pDest = mce->arguments->at(0)->expression;
        auto pBase = mce->arguments->at(2)->expression;
        auto pMax = mce->arguments->at(4)->expression;

        // Check the max value
        auto w = pDest->type->width_bits();
        // Add data unconditionally.
        auto args = new IR::Vector<IR::Argument>({ mce->arguments->at(3) });
        if (pMax->to<IR::Constant>() == nullptr || pBase->to<IR::Constant>() == nullptr)
            BUG("Only compile-time constants are supported for hash base offset and max value");

        if (pMax->to<IR::Constant>()->asUint64() < (1ULL << w))  {
            if (pBase->type->width_bits() != w)
                pBase = new IR::Cast(IR::Type::Bits::get(w), pBase);
            args->push_back(new IR::Argument(pBase));

            if (pMax->type->width_bits() != w)
                pMax = new IR::Cast(IR::Type::Bits::get(w), pMax);
            args->push_back(new IR::Argument(pMax));
        } else {
            ERROR_CHECK(pBase->to<IR::Constant>()->asInt() == 0,
                      "The base offset for a hash calculation must be zero");
        }

        auto member = new IR::Member(new IR::PathExpression(hashName), "get");

        auto result = new IR::AssignmentStatement(pDest,
            new IR::MethodCallExpression(node->srcInfo, member, args));

        structure->_map.emplace(node, result);
    }

    /// hash function is converted to an instance of hash extern in the enclosed control block
    void cvtHashFunction(const IR::MethodCallStatement *node) {
        auto control = findContext<IR::P4Control>();
        ERROR_CHECK(control != nullptr, "hash() must be used in a control block");
        const bool isIngress =
                (control->name == structure->getBlockName(ProgramStructure::INGRESS));

        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(mce != nullptr, "Malformed IR: method call expression cannot be nullptr");

        ERROR_CHECK(mce->arguments->size() > 3, "hash extern must have at least 4 arguments");
        auto typeArgs = new IR::Vector<IR::Type>({mce->typeArguments->at(0)});

        auto hashType = new IR::Type_Specialized(new IR::Type_Name("Hash"), typeArgs);
        auto hashName = cstring::make_unique(structure->unique_names, "hash", '_');
        structure->unique_names.insert(hashName);
        convertHashPrimitive(node, hashName);

        // create hash instance
        auto algorithm = mce->arguments->at(1)->clone();
        if (auto typeName = algorithm->to<IR::Member>()) {
            structure->typeNamesToDo.emplace(typeName, typeName);
            LOG3("add " << typeName << " to translation map"); }
        auto hashArgs = new IR::Vector<IR::Argument>({ algorithm });
        auto hashInst = new IR::Declaration_Instance(hashName, hashType, hashArgs);

        if (isIngress) {
            structure->ingressDeclarations.push_back(hashInst->to<IR::Declaration>());
        } else {
            structure->egressDeclarations.push_back(hashInst->to<IR::Declaration>());
        }
    }

    /// resubmit function is converted to an assignment on resubmit_type
    void cvtResubmitFunction(const IR::MethodCallStatement *node) {
        /*
         * translate resubmit() function in ingress control block to
         *
         * ig_intr_md_for_dprsr.resubmit_type = n;
         *
         */
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(mce != nullptr, "malformed IR in resubmit() function");
        auto control = findContext<IR::P4Control>();
        ERROR_CHECK(control != nullptr, "resubmit() must be used in a control block");
        ERROR_CHECK(control->name == structure->getBlockName(ProgramStructure::INGRESS),
                  "resubmit() can only be used in ingress control");
        IR::PathExpression *path = new IR::PathExpression("ig_intr_md_for_dprsr");
        auto mem = new IR::Member(path, "resubmit_type");
        unsigned resubmitId = getIndex(node, resubmitIndexHashes);
        if (resubmitId > Device::maxResubmitId()) {
            ::error("Too many resubmit() calls in %1%", control->name);
            return;
        }
        unsigned bits = static_cast<unsigned>(std::ceil(std::log2(Device::maxResubmitId())));
        auto idx = new IR::Constant(IR::Type::Bits::get(bits), resubmitId);
        auto stmt = new IR::AssignmentStatement(mem, idx);
        structure->_map.emplace(node, stmt);

        /*
         * In the ingress deparser, add the following code
         *
         * Resubmit() resubmit;
         * if (ig_intr_md_for_dprsr.resubmit_type == n)
         *    resubmit.emit({fields});
         *
         */

        // Only instantiate the extern for the first instance of resubmit()
        auto findDecl = [](std::vector<const IR::Declaration*> decls,
                           cstring name) -> const IR::Declaration * {
            for (auto d : decls)
                if (d->getName() == name) return d;
            return nullptr;
        };
        const IR::Declaration* resubmitDeclared =
            findDecl(structure->ingressDeparserDeclarations, "resubmit");

        if (resubmitDeclared == nullptr) {
            auto declArgs = new IR::Vector<IR::Argument>({});
            auto declType = new IR::Type_Name("Resubmit");
            auto decl = new IR::Declaration_Instance("resubmit",
                                                 declType, declArgs);
            structure->ingressDeparserDeclarations.push_back(decl);
        }

        auto fl = mce->arguments->at(0)->expression;   // resubmit field list
        /// compiler inserts resubmit_type as the format id to
        /// identify the resubmit group, it is 3 bits in size, but
        /// will be aligned to byte boundary in backend.
        auto new_fl = new IR::ListExpression({mem});
        for (auto f : fl->to<IR::ListExpression>()->components)
            new_fl->push_back(f);
        auto args = new IR::Vector<IR::Argument>(new IR::Argument(new_fl));
        auto expr = new IR::PathExpression(new IR::Path("resubmit"));
        auto member = new IR::Member(expr, "emit");
        auto typeArgs = new IR::Vector<IR::Type>();
        auto mcs = new IR::MethodCallStatement(
                new IR::MethodCallExpression(member, typeArgs, args));

        auto condExprPath = new IR::Member(
                new IR::PathExpression(new IR::Path("ig_intr_md_for_dprsr")),
                "resubmit_type");
        auto condExpr = new IR::Equ(condExprPath, idx);
        auto cond = new IR::IfStatement(condExpr, mcs, nullptr);
        structure->ingressDeparserStatements.push_back(cond);
    }

    void convertRandomPrimitive(const IR::MethodCallStatement *node, cstring randName) {
        auto mce = node->methodCall->to<IR::MethodCallExpression>();

        auto dest = mce->arguments->at(0)->expression;
        // ignore lower bound
        auto hi = mce->arguments->at(2);
        auto args = new IR::Vector<IR::Argument>();
        args->push_back(hi);

        auto method = new IR::PathExpression(randName);
        auto member = new IR::Member(method, "get");
        auto call = new IR::MethodCallExpression(node->srcInfo, member, args);
        auto stmt = new IR::AssignmentStatement(dest, call);
        structure->_map.emplace(node, stmt);
    }

    void cvtRandomFunction(const IR::MethodCallStatement *node) {
        auto control = findContext<IR::P4Control>();
        ERROR_CHECK(control != nullptr, "random() must be used in a control block");
        const bool isIngress =
                (control->name == structure->getBlockName(ProgramStructure::INGRESS));
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(mce != nullptr, "Malformed IR: method call expression cannot be nullptr");

        auto baseType = mce->arguments->at(0)->expression;
        auto typeArgs = new IR::Vector<IR::Type>({baseType->type});
        auto type = new IR::Type_Specialized(new IR::Type_Name("Random"), typeArgs);
        auto param = new IR::Vector<IR::Argument>();
        auto randName = cstring::make_unique(structure->unique_names, "random", '_');
        structure->unique_names.insert(randName);
        convertRandomPrimitive(node, randName);

        auto randInst = new IR::Declaration_Instance(randName, type, param);

        if (isIngress) {
            structure->ingressDeclarations.push_back(randInst->to<IR::Declaration>());
        } else {
            structure->egressDeclarations.push_back(randInst->to<IR::Declaration>());
        }
    }

    void implementUpdateChecksum(const IR::MethodCallStatement* uc,
                                 cstring which,
                                 std::vector<gress_t> deparserUpdateLocations) {
        auto mc = uc->methodCall->to<IR::MethodCallExpression>();

        auto condition = mc->arguments->at(0)->expression;
        auto fieldlist = mc->arguments->at(1)->expression;
        auto destfield = mc->arguments->at(2)->expression;

        for (auto location : deparserUpdateLocations) {
            IR::Declaration_Instance* decl = createChecksumDeclaration(structure, uc);

            if (location == INGRESS)
                 structure->ingressDeparserDeclarations.push_back(decl);
            else if (location == EGRESS)
                 structure->egressDeparserDeclarations.push_back(decl);

            IR::Vector<IR::Expression> exprs;

            for (auto f : fieldlist->to<IR::ListExpression>()->components)
                exprs.push_back(f);

            if (which == "update_checksum_with_payload") {
                if (location == EGRESS &&
                    parserChecksums->bridgedResidualChecksums.count(destfield)) {
                    auto pr = parserChecksums->bridgedResidualChecksums.at(destfield);
                    exprs.push_back(pr);
                }
            }

            IR::ListExpression* list = new IR::ListExpression(exprs);
            auto* updateCall = new IR::MethodCallExpression(
                    mc->srcInfo,
                    new IR::Member(new IR::PathExpression(decl->name), "update"),
                    { new IR::Argument(list) });

            IR::Statement* stmt = new IR::AssignmentStatement(destfield, updateCall);
            if (auto boolLiteral = condition->to<IR::BoolLiteral>()) {
                if (!boolLiteral->value) {
                    // Do not add the if-statement if the condition is always true.
                    stmt = nullptr;
                }
            } else {
                stmt = new IR::IfStatement(condition, stmt, nullptr);
            }

            if (stmt) {
                if (location == INGRESS)
                    structure->ingressDeparserStatements.push_back(stmt);
                else if (location == EGRESS)
                    structure->egressDeparserStatements.push_back(stmt);
            }
        }
    }

    void cvtUpdateChecksum(const IR::MethodCallStatement *call, cstring which) {
        auto block = findContext<IR::BlockStatement>();
        std::vector<gress_t> deparserUpdateLocations =
            getChecksumUpdateLocations(block, "calculated_field_update_location");

        if (analyzeChecksumCall(call, which))
            implementUpdateChecksum(call, which, deparserUpdateLocations);
    }

    /// build up a table for all metadata member that need to be translated.
    void postorder(const IR::Member *node) override {
        /// header/struct names appeared in p4_14_include/tofino/intrinsic_metadata.p4
        ordered_set<cstring> toTranslateInControl = {"standard_metadata",
                                                     "ig_intr_md_for_tm",
                                                     "ig_intr_md",
                                                     "ig_pg_md",
                                                     "ig_intr_md_for_mb",
                                                     "ig_intr_md_from_parser_aux",
                                                     "eg_intr_md",
                                                     "eg_intr_md_for_mb",
                                                     "eg_intr_md_from_parser_aux",
                                                     "eg_intr_md_for_oport"};
        ordered_set<cstring> toTranslateInParser = {"standard_metadata", "ig_prsr_ctrl"};
        auto gress = findOrigCtxt<IR::P4Control>();
        if (gress) {
            if (auto member = node->expr->to<IR::Member>()) {
                auto it = toTranslateInControl.find(member->member.name);
                if (it != toTranslateInControl.end()) {
                    structure->membersToDo.emplace(node, node);
                }
            } else if (auto expr = node->expr->to<IR::PathExpression>()) {
                auto path = expr->path->to<IR::Path>();
                CHECK_NULL(path);
                auto it = toTranslateInControl.find(path->name);
                if (it != toTranslateInControl.end()) {
                    if (gress->name == structure->getBlockName(ProgramStructure::INGRESS)) {
                        structure->pathsThread.emplace(node, INGRESS);
                        structure->pathsToDo.emplace(node, node);
                    } else if (gress->name == structure->getBlockName(ProgramStructure::EGRESS)) {
                        structure->pathsThread.emplace(node, EGRESS);
                        structure->pathsToDo.emplace(node, node);
                    } else {
                        WARNING("path " << node << " in "
                                        << gress->name.name << " is not translated");
                    }
                }
            } else if (auto expr = node->expr->to<IR::TypeNameExpression>()) {
                auto tn = expr->typeName->to<IR::Type_Name>();
                CHECK_NULL(tn);
                structure->typeNamesToDo.emplace(node, node);
            } else {
                WARNING("Unable to translate path " << node);
            }
        }
        auto parser = findOrigCtxt<IR::P4Parser>();
        if (parser) {
            if (auto expr = node->expr->to<IR::PathExpression>()) {
                auto path = expr->path->to<IR::Path>();
                CHECK_NULL(path);
                auto it = toTranslateInParser.find(path->name);
                if (it == toTranslateInParser.end())
                    return;
                if (auto type = expr->type->to<IR::Type_Name>()) {
                    if (type->path->name == "ingress_parser_control_signals") {
                        if (auto stmt = findContext<IR::AssignmentStatement>()) {
                            if (node->member == "parser_counter") {
                                ParserCounterConverter cvt(structure);
                                structure->_map.emplace(stmt, stmt->apply(cvt));
                            } else if (node->member == "priority") {
                                ParserPriorityConverter cvt(structure);
                                structure->_map.emplace(stmt, stmt->apply(cvt));
                            }
                        // handle parser counter in select() expression
                        } else if (findContext<IR::SelectExpression>()) {
                            ParserCounterSelectionConverter cvt(structure);
                            structure->_map.emplace(node, node->apply(cvt));
                        } else {
                            BUG("Invalid expression for parser counter");
                        }
                    }
                } else if (expr->type->is<IR::Type_Struct>()) {
                    structure->pathsToDo.emplace(node, node);
                } else {
                    WARNING("metadata " << node << " is not converted");
                }
            } else if (auto expr = node->expr->to<IR::TypeNameExpression>()) {
                auto tn = expr->typeName->to<IR::Type_Name>();
                CHECK_NULL(tn);
                structure->typeNamesToDo.emplace(node, node);
            } else {
                WARNING("Expression " << node << " is not converted");
            }
        }
    }

    void cvtActionProfile(const IR::Declaration_Instance* node) {
        auto type = node->type->to<IR::Type_Name>();
        ERROR_CHECK(type->path->name == "action_profile",
                  "action_profile converter cannot be applied to %1%", type->path->name);

        type = new IR::Type_Name("ActionProfile");
        auto result = new IR::Declaration_Instance(node->srcInfo, node->name, node->annotations,
                                                   type, node->arguments);
        structure->_map.emplace(node, result);
    }

    void cvtRegister(const IR::Declaration_Instance* node) {
        auto type = node->type->to<IR::Type_Specialized>();
        ERROR_CHECK(type != nullptr, "Invalid type for register converter");
        ERROR_CHECK(type->baseType->path->name == "register",
                  "register converter cannot be applied to %1%", type->baseType->path->name);
        BUG_CHECK(node->arguments->size() == 1, "register must have exactly one argument");
        BUG_CHECK(type->arguments->size() == 1, "register must have exactly one type argument");

        auto typeArgs = new IR::Vector<IR::Type>();
        auto eltype = type->arguments->at(0);
        if (auto bits = eltype->to<IR::Type::Bits>()) {
            auto width = 1 << ceil_log2(bits->size);  // round up to a power of 2
            if (width > 1 && width < 8) width = 8;  // 2/4 are not usable on tofino
            if (width != bits->size) {
                // Not a valid tofino register width -- round up to the next valid width?
                if (structure->backward_compatible && width <= 64) {
                    eltype = IR::Type::Bits::get(width, bits->isSigned);
                    warning("register %s width %d not supported, rounding up to %d",
                            node, bits->size, width);
                } else {
                    error("register %s width %d not supported", node, bits->size); } } }
        typeArgs->push_back(eltype);

        auto args = new IR::Vector<IR::Argument>();

        if (node->arguments->at(0)->expression->to<IR::Constant>()->asInt()) {
            args->push_back(node->arguments->at(0));
            typeArgs->push_back(IR::Type::Bits::get(32));
            type = new IR::Type_Specialized(
                new IR::Type_Name("Register"), typeArgs);
        } else {
            type = new IR::Type_Specialized(
                new IR::Type_Name("DirectRegister"), typeArgs);
        }

        auto decl = new IR::Declaration_Instance(
            node->srcInfo, node->name, node->annotations, type, args);
        structure->_map.emplace(node, decl);
    }

    void cvtActionSelector(const IR::Declaration_Instance* node) {
        auto type = node->type->to<IR::Type_Name>();
        ERROR_CHECK(type->path->name == "action_selector",
                  "action_selector converter cannot be applied to %1%", type->path->name);
        auto declarations = new IR::IndexedVector<IR::Declaration>();

        // Create a new instance of Hash<W>
        auto typeArgs = new IR::Vector<IR::Type>();
        auto w = node->arguments->at(2)->expression->to<IR::Constant>()->asInt();
        typeArgs->push_back(IR::Type::Bits::get(w));

        auto args = new IR::Vector<IR::Argument>();
        args->push_back(node->arguments->at(0));

        auto specializedType = new IR::Type_Specialized(
            new IR::Type_Name("Hash"), typeArgs);
        auto hashName = cstring::make_unique(
            structure->unique_names, node->name + "__hash_", '_');
        structure->unique_names.insert(hashName);
        declarations->push_back(
            new IR::Declaration_Instance(hashName, specializedType, args));

        args = new IR::Vector<IR::Argument>();
        // size
        args->push_back(node->arguments->at(1));
        // hash
        args->push_back(new IR::Argument(new IR::PathExpression(hashName)));
        // selector_mode
        auto sel_mode = new IR::Member(
            new IR::TypeNameExpression("SelectorMode_t"), "FAIR");
        if (auto anno = node->annotations->getSingle("mode")) {
            auto mode = anno->expr.at(0)->to<IR::StringLiteral>();
            if (mode->value == "resilient")
                sel_mode->member = IR::ID("RESILIENT");
            else if (mode->value != "fair" && mode->value != "non_resilient")
                BUG("Selector mode provided for the selector is not supported", node);
        } else {
            WARNING("No mode specified for the selector %s. Assuming fair" << node);
        }
        args->push_back(new IR::Argument(sel_mode));

        type = new IR::Type_Name("ActionSelector");
        declarations->push_back(new IR::Declaration_Instance(
            node->srcInfo, node->name, node->annotations, type, args));
        structure->_map.emplace(node, declarations);
    }

    void cvtCounterDecl(const IR::Declaration_Instance* node) {
        auto type = node->type->to<IR::Type_Name>();
        if (!type) return;
        auto typeArgs = new IR::Vector<IR::Type>();
        // type<W>
        if (auto anno = node->annotations->getSingle("min_width")) {
            auto min_width = anno->expr.at(0)->as<IR::Constant>().asInt();
            typeArgs->push_back(IR::Type::Bits::get(min_width));
        } else {
            auto min_width = IR::Type::Bits::get(32);
            typeArgs->push_back(min_width);
            WARNING("Could not infer min_width for counter %s, using bit<32>" << node);
        }
        // type<S>
        if (auto s = node->arguments->at(0)->expression->to<IR::Constant>()) {
            typeArgs->push_back(s->type->to<IR::Type_Bits>());
        }

        auto specializedType = new IR::Type_Specialized(new IR::Type_Name("Counter"), typeArgs);
        auto decl = new IR::Declaration_Instance(node->srcInfo, node->name, node->annotations,
                                                 specializedType, node->arguments);
        structure->_map.emplace(node, decl);
    }

    void cvtMeterDecl(const IR::Declaration_Instance* node) {
        auto type = node->type->to<IR::Type_Name>();
        if (!type) return;
        auto typeArgs = new IR::Vector<IR::Type>();
        if (auto s = node->arguments->at(0)->expression->to<IR::Constant>()) {
            typeArgs->push_back(s->type->to<IR::Type_Bits>());
        }
        auto specializedType = new IR::Type_Specialized(new IR::Type_Name("Meter"), typeArgs);
        auto decl = new IR::Declaration_Instance(node->srcInfo, node->name, node->annotations,
                                                 specializedType, node->arguments);
        structure->_map.emplace(node, decl);
    }

    void cvtDirectMeterDecl(const IR::Declaration_Instance* node) {
        auto decl = new IR::Declaration_Instance(node->srcInfo, node->name, node->annotations,
                                                 new IR::Type_Name("DirectMeter"), node->arguments);
        structure->_map.emplace(node, decl);
    }

    void cvtDirectCounterDecl(const IR::Declaration_Instance *node) {
        auto typeArgs = new IR::Vector<IR::Type>();
        if (auto anno = node->annotations->getSingle("min_width")) {
            auto min_width = anno->expr.at(0)->as<IR::Constant>().asInt();
            typeArgs->push_back(IR::Type::Bits::get(min_width));
        } else {
            auto min_width = IR::Type::Bits::get(32);
            typeArgs->push_back(min_width);
            WARNING("Could not infer min_width for counter %s, using bit<32>" << node);
        }
        auto specializedType = new IR::Type_Specialized(
            new IR::Type_Name("DirectCounter"), typeArgs);
        auto decl = new IR::Declaration_Instance(
            node->srcInfo, node->name, node->annotations, specializedType, node->arguments);
        structure->_map.emplace(node, decl);
    }

    void cvtExternDeclaration(const IR::Declaration_Instance *node, cstring name) {
        if (name == "counter") {
            cvtCounterDecl(node);
        } else if (name == "direct_counter") {
            cvtDirectCounterDecl(node);
        } else if (name == "meter") {
            cvtMeterDecl(node);
        } else if (name == "direct_meter") {
            cvtDirectMeterDecl(node);
        } else if (name == "action_profile") {
            cvtActionProfile(node);
        } else if (name == "action_selector") {
            cvtActionSelector(node);
        } else if (name == "register") {
            cvtRegister(node);
        }
    }

    void postorder(const IR::Declaration_Instance *node) override {
        if (node->type->is<IR::Type_Specialized>()) {
            auto type = node->type->to<IR::Type_Specialized>()->baseType;
            if (type->path->name == "V1Switch") {
                auto type_h = node->type->to<IR::Type_Specialized>()->arguments->at(0);
                auto type_m = node->type->to<IR::Type_Specialized>()->arguments->at(1);
                structure->type_h = type_h->to<IR::Type_Name>()->path->name;
                structure->type_m = type_m->to<IR::Type_Name>()->path->name;
            }
            cvtExternDeclaration(node, type->path->name);
        } else if (auto type = node->type->to<IR::Type_Name>()) {
            cvtExternDeclaration(node, type->path->name);
        }
    }

    void postorder(const IR::MethodCallStatement *node) override {
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        CHECK_NULL(mce);
        auto mi = P4::MethodInstance::resolve(node, refMap, typeMap);
        if (auto em = mi->to<P4::ExternMethod>()) {
            cstring name = em->actualExternType->name;
            if (name == "direct_meter") {
                DirectMeterConverter cvt(structure, refMap);
                structure->_map.emplace(node, node->apply(cvt));
            } else if (name == "meter") {
                MeterConverter cvt(structure);
                structure->_map.emplace(node, node->apply(cvt));
            } else if (name == "register") {
                RegisterConverter cvt(structure);
                structure->_map.emplace(node, node->apply(cvt));
            }
            // Counter method needs no translation
        } else if (auto ef = mi->to<P4::ExternFunction>()) {
            cstring name = ef->method->name;
            if (name == "hash") {
                cvtHashFunction(node);
            } else if (name == "resubmit") {
                cvtResubmitFunction(node);
            } else if (name == "mark_to_drop" || name == "drop") {
                cvtDropFunction(node);
            } else if (name == "random") {
                cvtRandomFunction(node);
            } else if (name == "digest") {
                cvtDigestFunction(node);
            } else if (name == "clone") {
                cvtCloneFunction(node, /* hasData = */ false);
            } else if (name == "clone3") {
                cvtCloneFunction(node, /* hasData = */ true);
            } else if (name == "invalidate_digest") {
                cvtInvalidateDigestFunction(node);
            } else if (name == "update_checksum" ||
                       name == "update_checksum_with_payload") {
                cvtUpdateChecksum(node, name);
            } else if (name == "execute_meter_with_color") {
                cvtExecuteMeterFunctiion(node);
            }
        }
    }

    // if a path refers to a global declaration, move
    // the global declaration to local control;
    void postorder(const IR::PathExpression *node) override {
        auto path = node->path;
        auto it = structure->global_instances.find(path->name);
        if (it != structure->global_instances.end()) {
            if (globals.find(path->name) != globals.end())
                return;
            auto control = findContext<IR::P4Control>();
            BUG_CHECK(control != nullptr,
                      "unable to reference global instance from non-control block");
            if (control->name == structure->getBlockName(ProgramStructure::INGRESS)) {
                structure->ingressDeclarations.push_back(it->second);
                globals.insert(path->name);
            } else if (control->name == structure->getBlockName(ProgramStructure::EGRESS)) {
                structure->egressDeclarations.push_back(it->second);
                globals.insert(path->name);
            } else {
                BUG("unexpected reference to global instance from %1%", control->name);
            }
        }
    }

    void postorder(const IR::Property *node) override {
        if (node->name == "support_timeout") {
            auto idle_timeout = new IR::Property("idle_timeout", node->annotations,
                    node->value, node->isConstant);
            structure->_map.emplace(node, idle_timeout);
        }
    }

 private:
    /**
     * Find the "first" table in which the action is present
     */
    const IR::P4Table *findTable(const IR::P4Control *control, const IR::P4Action *action) {
        auto tables = control->getDeclarations()->where([action] (const IR::IDeclaration *d) {
                if (!d->is<IR::P4Table>())
                    return false;
                auto t = d->to<IR::P4Table>();
                LOG3("Searching for " << action->getName() << " in table " << t->getName());
                return t->getActionList()->getDeclaration(action->getName()) != nullptr;
            });
        try {
            auto t = tables->single();
            LOG3("found " << t->getName() << " as table candidate");
            return t->to<IR::P4Table>();
        } catch (...) {
            tables->reset();  // Enumerators are weird!!
            if (tables->count() > 1)
                P4C_UNIMPLEMENTED("action %1% present in multiple tables", action->getName());
            return nullptr;
        }
        return nullptr;
    }

    // Concatenate a field string with list of fields within a method call
    // argument. The field list is specified as a ListExpression
    void generate_fields_string(const IR::MethodCallStatement *node,
                                                std::string& fieldString) {
        std::ostringstream fieldListString;
        for (auto argument : *node->methodCall->arguments) {
            if (auto fieldList = argument->expression->to<IR::ListExpression>()) {
                for (auto comp : fieldList->components) {
                    fieldListString << comp;
                }
            }
            fieldString += fieldListString.str();
        }
    }

    // Generate a 64-bit hash for input field string, lookup hash vector for
    // presence of hash, add new entry if not found. This function is common to
    // resubmit, digest and clone indexing
    unsigned getIndex(const IR::MethodCallStatement *node,
            std::map<unsigned long, unsigned>& hashIndexMap) {
        std::string fieldsString;
        generate_fields_string(node, fieldsString);
        std::hash<std::string> hashFn;

        auto fieldsStringHash = hashFn(fieldsString);
        if (hashIndexMap.count(fieldsStringHash) == 0)
            hashIndexMap.emplace(fieldsStringHash, hashIndexMap.size());

        return hashIndexMap[fieldsStringHash];
    }
};

// In P4-14, struct field can only be Type_Bits, therefore, when translating to
// P4-16, all the corresponding struct field should also be Type_Bits.
// However, target architectures such as jbay.p4 or tofino.p4 have Type_Boolean
// in some of the struct fields, this pass will convert these fields to
// Type_Bits.  The conversion only apply to struct fields that are defined in
// the target architecture file and are annotated with "__intrinsic_metadata".
class LoweringType : public Transform {
    std::map<cstring, unsigned> enum_encoding;

 public:
    LoweringType() {}

    const IR::Node* postorder(IR::StructField* node) override {
        auto ctxt = findOrigCtxt<IR::Type_StructLike>();
        if (!ctxt)
            return node;
        if (!ctxt->annotations->getSingle("__intrinsic_metadata"))
            return node;
        if (!node->type->is<IR::Type_Boolean>())
            return node;
        return new IR::StructField(node->srcInfo, node->name,
                                   node->annotations, new IR::Type_Bits(1, false));
    }

    const IR::Node* postorder(IR::Type_Enum* node) override {
        if (node->name == "MeterColor_t")
            enum_encoding.emplace(node->name, 2);
        return node;
    }

    const IR::Node* postorder(IR::Type_Name* node) override {
        auto name = node->path->name;
        if (enum_encoding.count(name)) {
            auto size = enum_encoding.at(name);
            return new IR::Type_Bits(size, false);
        }
        return node;
    }
};

class CollectParserChecksums : public Inspector {
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;

 public:
    std::vector<const IR::MethodCallStatement*> verifyChecksums;
    std::vector<const IR::MethodCallStatement*> residualChecksums;
    std::map<const IR::MethodCallStatement*, std::vector<gress_t>> parserUpdateLocations;
    std::map<const IR::MethodCallStatement*, std::vector<gress_t>> deparserUpdateLocations;

    CollectParserChecksums(P4::ReferenceMap *refMap, P4::TypeMap *typeMap)
            : refMap(refMap), typeMap(typeMap) {
        setName("CollectParserChecksums");
    }

    void postorder(const IR::MethodCallStatement *node) override {
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        CHECK_NULL(mce);
        auto mi = P4::MethodInstance::resolve(node, refMap, typeMap);
        if (auto ef = mi->to<P4::ExternFunction>()) {
            if (ef->method->name == "verify_checksum" &&
                analyzeChecksumCall(node, "verify_checksum")) {
                verifyChecksums.push_back(node);
            } else if (ef->method->name == "update_checksum_with_payload" &&
                analyzeChecksumCall(node, "update_checksum_with_payload")) {
                residualChecksums.push_back(node);

                auto block = findContext<IR::BlockStatement>();
                parserUpdateLocations[node] =
                    getChecksumUpdateLocations(block, "residual_checksum_parser_update_location");
                deparserUpdateLocations[node] =
                    getChecksumUpdateLocations(block, "calculated_field_update_location");
            }
        }
    }
};

class InsertParserChecksums : public Inspector {
 public:
    InsertParserChecksums(TranslateParserChecksums* translate,
                          const CollectParserChecksums* collect,
                          const P4ParserGraphs*,
                          ProgramStructure *structure)
        : translate(translate),
          collect(collect),
          structure(structure) { }

 private:
    TranslateParserChecksums* translate;
    const CollectParserChecksums* collect;
    ProgramStructure *structure;

    std::map<const IR::MethodCallStatement*, const IR::Declaration*> verifyDeclarationMap;

    std::map<const IR::MethodCallStatement*, IR::Declaration_Instance*>
        ingressParserResidualChecksumDecls, egressParserResidualChecksumDecls;

    unsigned residualChecksumCnt = 0;

    typedef std::map<const IR::ParserState*, std::vector<const IR::Member*> > StateToExtracts;
    typedef std::map<const IR::Member*, const IR::ParserState*> ExtractToState;

    StateToExtracts stateToExtracts;
    ExtractToState extractToState;

    struct CollectExtractMembers : public Inspector {
        CollectExtractMembers(
            StateToExtracts& stateToExtracts, ExtractToState& extractToState) :
                stateToExtracts(stateToExtracts), extractToState(extractToState) { }

        StateToExtracts& stateToExtracts;
        ExtractToState& extractToState;

        void postorder(const IR::MethodCallStatement* statement) override {
            auto* call = statement->methodCall;
            auto* method = call->method->to<IR::Member>();
            auto* state = findContext<IR::ParserState>();

            if (method && method->member == "extract") {
                for (auto m : *(call->arguments)) {
                    auto* mem = m->expression->to<IR::Member>();
                    stateToExtracts[state].push_back(mem);
                    extractToState[mem] = state;
                }
            }
        }
    };

    profile_t init_apply(const IR::Node* root) override {
        CollectExtractMembers cem(stateToExtracts, extractToState);
        root->apply(cem);
        return Inspector::init_apply(root);
    }

    // FIXME -- yet another 'deep' comparison for expressions
    static bool equiv(const IR::Expression *a, const IR::Expression *b) {
        if (a == b) return true;
        if (typeid(*a) != typeid(*b)) return false;
        if (auto ma = a->to<IR::Member>()) {
            auto mb = b->to<IR::Member>();
            return ma->member == mb->member && equiv(ma->expr, mb->expr); }
        if (auto pa = a->to<IR::PathExpression>()) {
            auto pb = b->to<IR::PathExpression>();
            return pa->path->name == pb->path->name; }
        return false;
    }

    static bool belongsTo(const IR::Member* a, const IR::Member* b) {
        if (!a || !b) return false;

        // case 1: a is field, b is field
        if (equiv(a, b)) return true;

        // case 2: a is field, b is header
        if (a->type->is<IR::Type::Bits>()) {
            if (equiv(a->expr, b)) return true;
        }

        return false;
    }

    void implementVerifyChecksum(const IR::MethodCallStatement* vc,
                                 const IR::ParserState* state) {
        cstring stateName = state->name;
        auto& extracts = stateToExtracts[state];

        auto mc = vc->methodCall->to<IR::MethodCallExpression>();

        auto fieldlist = mc->arguments->at(1)->expression;
        auto destfield = mc->arguments->at(2)->expression;

        // check if any of the fields or dest belong to extracts
        // TODO(zma) verify on ingress only?

        const IR::Declaration* decl = nullptr;

        if (verifyDeclarationMap.count(vc)) {
            decl = verifyDeclarationMap.at(vc);
        } else {
            decl = createChecksumDeclaration(structure, vc);
            verifyDeclarationMap[vc] = decl;
            structure->ingressParserDeclarations.push_back(decl);
        }

        for (auto f : fieldlist->to<IR::ListExpression>()->components) {
            for (auto extract : extracts) {
                if (belongsTo(f->to<IR::Member>(), extract)) {
                    auto addCall = new IR::MethodCallStatement(mc->srcInfo,
                        new IR::Member(new IR::PathExpression(decl->name), "add"),
                                                              { new IR::Argument(f) });

                    structure->ingressParserStatements[stateName].push_back(addCall);
                    translate->ingressVerifyDeclToStates[decl].insert(state);
                }
            }
        }

        for (auto extract : extracts) {
            if (belongsTo(destfield->to<IR::Member>(), extract)) {
                BUG_CHECK(decl, "No fields have been added before verify?");

                auto addCall = new IR::MethodCallStatement(mc->srcInfo,
                        new IR::Member(new IR::PathExpression(decl->name), "add"),
                                                              { new IR::Argument(destfield) });

                structure->ingressParserStatements[stateName].push_back(addCall);
                translate->ingressVerifyDeclToStates[decl].insert(state);
            }
        }
    }

    void implementParserResidualChecksum(const IR::MethodCallStatement *rc,
                                         const IR::ParserState* state,
                                         const std::vector<gress_t>& parserUpdateLocations,
                                         const std::vector<gress_t>& deparserUpdateLocations) {
        cstring stateName = state->name;
        auto& extracts = stateToExtracts[state];

        auto mc = rc->methodCall->to<IR::MethodCallExpression>();

        auto condition = mc->arguments->at(0)->expression;
        auto fieldlist = mc->arguments->at(1)->expression;
        auto destfield = mc->arguments->at(2)->expression;

        bool needBridging = parserUpdateLocations.size() == 1 &&
                            parserUpdateLocations[0] == INGRESS &&
                            deparserUpdateLocations.size() == 1 &&
                            deparserUpdateLocations[0] == EGRESS;

        if (needBridging && !translate->bridgedResidualChecksums.count(destfield)) {
            auto *compilerMetadataPath =
                    new IR::PathExpression("compiler_generated_meta");

            auto *compilerMetadataDecl = const_cast<IR::Type_Struct*>(
                structure->type_declarations.at("compiler_generated_metadata_t")
                         ->to<IR::Type_Struct>());

            std::stringstream residualFieldName;
            residualFieldName << "residual_checksum_";
            residualFieldName << residualChecksumCnt++;

            auto* residualChecksum = new IR::Member(compilerMetadataPath,
                                              residualFieldName.str().c_str());

            compilerMetadataDecl->fields.push_back(
                new IR::StructField(residualFieldName.str().c_str(),
                                    IR::Type::Bits::get(16)));

            translate->bridgedResidualChecksums[destfield] = residualChecksum;
        }

        for (auto location : parserUpdateLocations) {
            std::vector<const IR::Declaration *>* parserDeclarations = nullptr;
            std::vector<const IR::StatOrDecl *>* parserStatements = nullptr;

            std::map<const IR::MethodCallStatement*,
                    IR::Declaration_Instance*>* parserResidualChecksumDecls = nullptr;

            if (location == INGRESS) {
                parserDeclarations = &structure->ingressParserDeclarations;
                parserStatements = &structure->ingressParserStatements[stateName];
                parserResidualChecksumDecls = &ingressParserResidualChecksumDecls;
            } else if (location == EGRESS) {
                parserDeclarations = &structure->egressParserDeclarations;
                parserStatements = &structure->egressParserStatements[stateName];
                parserResidualChecksumDecls = &egressParserResidualChecksumDecls;
            }

            IR::Declaration_Instance* decl = nullptr;
            auto it = parserResidualChecksumDecls->find(rc);
            if (it == parserResidualChecksumDecls->end()) {
                decl = createChecksumDeclaration(structure, rc);
                parserDeclarations->push_back(decl);
                (*parserResidualChecksumDecls)[rc] = decl;
            } else {
                decl = parserResidualChecksumDecls->at(rc);
            }

            for (auto extract : extracts) {
                for (auto f : fieldlist->to<IR::ListExpression>()->components) {
                    if (belongsTo(f->to<IR::Member>(), extract)) {
                        auto subtractCall = new IR::MethodCallStatement(mc->srcInfo,
                            new IR::Member(new IR::PathExpression(decl->name), "subtract"),
                                                                  { new IR::Argument(f) });

                        parserStatements->push_back(subtractCall);
                    }
                }

                if (belongsTo(destfield->to<IR::Member>(), extract)) {
                    auto subtractCall = new IR::MethodCallStatement(mc->srcInfo,
                        new IR::Member(new IR::PathExpression(decl->name), "subtract"),
                                                              { new IR::Argument(destfield) });

                    parserStatements->push_back(subtractCall);

                    auto* getCall = new IR::MethodCallExpression(
                            mc->srcInfo,
                            new IR::Member(new IR::PathExpression(decl->name), "get"),
                            { });

                    auto* residualChecksum = needBridging ?
                                             translate->bridgedResidualChecksums.at(destfield) :
                                             destfield;

                    IR::Statement* stmt = new IR::AssignmentStatement(residualChecksum, getCall);
                    if (auto boolLiteral = condition->to<IR::BoolLiteral>()) {
                        if (!boolLiteral->value) {
                            // Do not add the if-statement if the condition is always true.
                            stmt = nullptr;
                        }
                    }

                    if (stmt)
                        parserStatements->push_back(stmt);
                }
            }
        }
    }

    void postorder(const IR::ParserState *state) override {
        // see if any of the "verify_checksum" or "update_checksum_with_payload" statement
        // is relavent to this state. If so, convert to TNA function calls.
        for (auto* vc : collect->verifyChecksums) {
            implementVerifyChecksum(vc, state);
        }

        for (auto* rc : collect->residualChecksums) {
            implementParserResidualChecksum(rc, state,
                                            collect->parserUpdateLocations.at(rc),
                                            collect->deparserUpdateLocations.at(rc));
        }
    }
};

TranslateParserChecksums::TranslateParserChecksums(ProgramStructure *structure,
                                                   P4::ReferenceMap *refMap,
                                                   P4::TypeMap *typeMap)
        : parserGraphs(refMap, typeMap, cstring()) {
    auto collectParserChecksums = new BFN::V1::CollectParserChecksums(refMap, typeMap);

    addPasses({&parserGraphs,
               collectParserChecksums,
               new BFN::V1::InsertParserChecksums(this,
                                                  collectParserChecksums,
                                                  &parserGraphs,
                                                  structure)
              });
}

class InsertChecksumError : public PassManager {
 public:
    std::map<cstring,
        std::map<const IR::Declaration*,
            std::set<cstring>>> endStates;

    struct ComputeEndStates : public Inspector {
        InsertChecksumError* self;

        explicit ComputeEndStates(InsertChecksumError* self) : self(self) { }

        void printStates(const std::set<const IR::ParserState*>& states) {
            for (auto s : states)
                std::cout << "   " << s->name << std::endl;
        }

        std::set<cstring>
        computeChecksumEndStates(const std::set<const IR::ParserState*>& calcStates) {
            auto& parserGraphs = self->translate->parserGraphs;

            if (LOGGING(3)) {
                std::cout << "calc states are:" << std::endl;
                printStates(calcStates);
            }

            std::set<const IR::ParserState*> endStates;

            // A calculation state is a verification end state if no other state of the
            // same calculation is its descendant. Otherwise, include all of the state's
            // children states that are not a calculation state.

            for (auto* a : calcStates) {
                bool isEndState = true;
                for (auto* b : calcStates) {
                    if (parserGraphs.is_ancestor(a, b)) {
                        isEndState = false;
                        break;
                    }
                }
                if (isEndState) {
                    endStates.insert(a);
                } else {
                    if (parserGraphs.succs.count(a)) {
                        for (auto* succ : parserGraphs.succs.at(a)) {
                            if (calcStates.count(succ))
                                continue;

                            for (auto* s : calcStates) {
                                if (!parserGraphs.is_ancestor(succ, s)) {
                                    endStates.insert(succ);
                                }
                            }
                        }
                    }
                }
            }

            BUG_CHECK(!endStates.empty(), "Unable to find verification end state?");

            if (LOGGING(3)) {
                std::cout << "end states are:" << std::endl;
                printStates(endStates);
            }

            std::set<cstring> rv;
            for (auto s : endStates)
                rv.insert(s->name);

            return rv;
        }

        bool preorder(const IR::BFN::TranslatedP4Parser* parser) override {
            // XXX(zma) verify on ingress only
            if (parser->thread != INGRESS)
                return false;

            // compute checksum end states
            for (auto kv : self->translate->ingressVerifyDeclToStates)
                self->endStates[parser->name][kv.first] = computeChecksumEndStates(kv.second);

            return false;
        }
    };

    // XXX(zma) we probably don't want to insert statement into the "accept" state
    // since this is a special state. Add a dummy state before "accept" if it is
    // a checksum verification end state.
    struct InsertBeforeAccept : public Transform {
        const IR::Node* preorder(IR::BFN::TranslatedP4Parser* parser) override {
            for (auto& kv : self->endStates[parser->name]) {
                if (kv.second.count("accept")) {
                    auto* newState =
                        AddIntrinsicMetadata::createGeneratedParserState(
                            "before_accept", {}, "accept");
                    parser->states.push_back(newState);
                    kv.second.erase("accept");
                    kv.second.insert("__before_accept");
                    LOG3("add dummy state before \"accept\"");
                }
            }

            return parser;
        }

        const IR::Node* postorder(IR::PathExpression* path) override {
            auto parser = findContext<IR::BFN::TranslatedP4Parser>();
            auto state = findContext<IR::ParserState>();
            auto select = findContext<IR::SelectCase>();

            if (parser && state && select) {
                bool isCalcState = false;

                for (auto kv : self->translate->ingressVerifyDeclToStates) {
                    for (auto s : kv.second) {
                        if (s->name == state->name) {
                            isCalcState = true;
                            break; } } }

                if (!isCalcState)
                    return path;

                for (auto& kv : self->endStates[parser->name]) {
                    if (path->path->name == "accept" && kv.second.count("__before_accept")) {
                        path = new IR::PathExpression("__before_accept");
                        LOG3("modify transition to \"before_accept\"");
                    }
                }
            }

            return path;
        }

        InsertChecksumError* self;

        explicit InsertBeforeAccept(InsertChecksumError* self) : self(self) { }
    };

    struct InsertEndStates : public Transform {
        const IR::Node* preorder(IR::ParserState* state) override {
            auto parser = findContext<IR::BFN::TranslatedP4Parser>();

            if (state->name == "reject")
                return state;

            for (auto& kv : self->endStates[parser->name]) {
                auto* decl = kv.first;
                for (auto endState : kv.second) {
                    if (endState == state->name) {
                        auto* checksumError = createChecksumError(decl, parser->thread);
                        state->components.push_back(checksumError);

                        LOG3("verify " << toString(parser->thread) << " "
                             << decl->name << " in state " << endState);
                    }
                }
            }

            return state;
        }

        InsertChecksumError* self;

        explicit InsertEndStates(InsertChecksumError* self) : self(self) { }
    };

    explicit InsertChecksumError(const V1::TranslateParserChecksums* translate) :
        translate(translate) {
        addPasses({new ComputeEndStates(this),
                   new InsertBeforeAccept(this),
                   new InsertEndStates(this),
             });
    }

    const V1::TranslateParserChecksums* translate;
};

}  // namespace V1

/// The general work flow of architecture translation consists of the following steps:
/// * analyze original source program to build a programStructure that represent original program.
/// * construct symbol tables of each IR type.
/// * iterate through the symbol tables, and perform transformation on each entry.
/// * update program structure with transform IR node from symbol table.
/// * reprint a valid P16 program to program structure.
SimpleSwitchTranslation::SimpleSwitchTranslation(P4::ReferenceMap* refMap,
                                                 P4::TypeMap* typeMap, BFN_Options& options) {
    setName("Translation");
    addDebugHook(options.getDebugHook());
    auto evaluator = new P4::EvaluatorPass(refMap, typeMap);
    auto structure = new BFN::V1::ProgramStructure;
    if (options.backward_compatible)
        structure->backward_compatible = true;
    auto parserChecksums = new V1::TranslateParserChecksums(structure, refMap, typeMap);
    addPasses({
        new P4::TypeChecking(refMap, typeMap, true),
        new RemoveExternMethodCallsExcludedByAnnotation,
        new V1::NormalizeProgram(),
        evaluator,
        new VisitFunctor([structure, evaluator]() {
            structure->toplevel = evaluator->getToplevelBlock(); }),
        new TranslationFirst(),
        new V1::LoadTargetArchitecture(structure),
        new V1::RemoveNodesWithNoMapping(),
        new V1::AnalyzeProgram(structure),
        parserChecksums,
        new V1::ConstructSymbolTable(structure, refMap, typeMap, parserChecksums),
        new GenerateTofinoProgram(structure),
        new V1::LoweringType(),
        new V1::InsertChecksumError(parserChecksums),
        new TranslationLast(),
        new AddIntrinsicMetadata,
        new P4::ClonePathExpressions,
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
        new RemoveSetMetadata(refMap, typeMap),
        new TranslatePhase0(refMap, typeMap),
        new P4::ClonePathExpressions,
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
        new BFN::AddTnaBridgeMetadata(refMap, typeMap),
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
    });
}

}  // namespace BFN
