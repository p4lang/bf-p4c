/**
 * Copyright 2013-2024 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */

#include "check_uninitialized_read.h"

#include "bf-p4c/common/table_printer.h"
#include "bf-p4c/lib/error_type.h"
#include "bf-p4c/mau/table_dependency_graph.h"

// FindUninitializedAndOverlayedReads
bool FindUninitializedAndOverlayedReads::preorder(const IR::BFN::DeparserParameter *param) {
    if (param->source) pov_protected_fields.insert(phv.field(param->source->field));
    return false;
}

bool FindUninitializedAndOverlayedReads::preorder(const IR::BFN::Digest *digest) {
    pov_protected_fields.insert(phv.field(digest->selector->field));
    return false;
}

void FindUninitializedAndOverlayedReads::end_apply() {
    Log::TempIndent indent;
    LOG1("FindUninitializedAndOverlayedReads end_apply" << indent);

    auto is_ignored_field = [&](const PHV::Field &field) {
        if (pragmas.pa_no_init().getFields().count(&field)) {
            LOG3("\tIgnore fields with pa_no_init pragma : " << field);
            return true;
        } else if (field.pov) {
            // pov is always initialized.
            LOG3("\tIgnore pov bits: " << field);
            return true;
        } else if (field.is_padding()) {
            // padding fields that are generated by the compiler should be ignored.
            LOG3("\tIgnore padding field: " << field);
            return true;
        } else if (field.is_deparser_zero_candidate()) {
            LOG3("\tIgnore deparser zero field: " << field);
            return true;
        } else if (field.is_overlayable()) {
            LOG3("\tIgnore overlayable field: " << field);
            return true;
        } else if (!Device::hasMetadataPOV()) {
            // Only for tofino, if a field is invalidated by the arch, then this field is pov
            // bit protected and will not overlay with other fields. So no need to check it.
            return field.is_invalidate_from_arch();
        } else {
            // For all fields that are pov bit protected fields, no need to check it, since no
            // write means pov bit remains invalid.
            for (const auto &pov_protected_field : pov_protected_fields) {
                if (pov_protected_field->name == field.name) return true;
            }
            return false;
        }
    };

    // If a table is placed, its stage value is set and can be directly accessed.
    // If a table is not placed we can use min stage from Dependency graph which gives the earliest
    // possible stage.
    //
    // For traditional compilation
    // - post phv allocation no table placement hence no stage info
    // - post table allocation table placed we have stage info
    // For alt phv alloc compilation
    // - post phv allocation we have stage info as trivial alloc
    // is followed by a placement round.
    auto get_min_stage = [&](const IR::BFN::Unit *u) {
        int min_stage = Device::numStages();
        if (auto *table = u->to<IR::MAU::Table>()) {
            min_stage = table->stage() > -1 ? table->stage() : deps.min_stage(table);
        } else if (u->is<IR::BFN::Parser>() || u->is<IR::BFN::ParserState>()) {
            min_stage = -1;
        }
        return min_stage;
    };

    auto get_slice_defs = [&](const PHV::AllocSlice &sl) {
        FieldDefUse::LocPairSet slice_defs;
        auto lr_start = sl.getEarliestLiveness();
        auto lr_end = sl.getLatestLiveness();

        for (const auto &def : defuse.getAllDefs(sl.field()->id)) {
            le_bitrange bits;
            phv.field(def.second, &bits);
            int def_stage = get_min_stage(def.first);
            if (bits.overlaps(sl.field_slice()) &&
                ((def_stage >= lr_start.first && def_stage < lr_end.first) ||
                 (def_stage == lr_end.first && lr_end.second.isWrite()))) {
                slice_defs.insert(def);
            }
        }
        return slice_defs;
    };

    auto get_slice_uses = [&](const PHV::AllocSlice &sl) {
        FieldDefUse::LocPairSet slice_uses;
        auto lr_start = sl.getEarliestLiveness();
        auto lr_end = sl.getLatestLiveness();

        for (auto &use : defuse.getAllUses(sl.field()->id)) {
            le_bitrange bits;
            phv.field(use.second, &bits);
            int use_stage = get_min_stage(use.first);
            if (bits.overlaps(sl.field_slice()) &&
                ((use_stage > lr_start.first && use_stage <= lr_end.first) ||
                 (use_stage == lr_start.first && lr_start.second.isRead()))) {
                slice_uses.insert(use);
            }
        }
        return slice_uses;
    };

    // Gather all uninitialized reads identified by algorithm
    std::set<uninit_read> uninit_reads;

    // Get all fields
    for (const auto &kv : phv.get_all_fields()) {
        const auto &field = kv.second;
        LOG3("For Field : " << field);
        if (is_ignored_field(field)) continue;
        // Get alloc slices for field
        for (const auto &fsl : field.get_alloc()) {
            LOG4("\twith field slice " << fsl);
            const auto &cont = fsl.container();
            // Skip TPHV candidates
            if (cont.type().kind() == PHV::Kind::tagalong) continue;
            // Get container slice
            auto csl = fsl.container_slice();
            // Get all slices in container
            for (const auto &f2sl : phv.get_slices_in_container(cont)) {
                // Skip same slice
                if (fsl == f2sl) continue;
                // Skip non overlapping slice
                auto csl2 = f2sl.container_slice();
                if (!csl.overlaps(csl2)) continue;
                auto *field2 = f2sl.field();
                if (phv.isFieldMutex(&field, field2)) continue;
                LOG5("\t\tFound container overlap with slice: " << f2sl);
                // For an overlap get defuse to check if current alloc slice is
                // uninitialized
                // First get all uses for current field
                for (const auto &use : get_slice_uses(fsl)) {
                    // For each use get previous defs
                    const auto &defs_of_use = defuse.getDefs(use);
                    // No defs for a use indicates an uninitialized read for the field
                    // slice.
                    // Based on control plane programming this can potentially corrupt the
                    // field slice value if it has an overlay and the overlayed field is
                    // live before or during the slice live range.
                    bool nodefs = defs_of_use.empty();
                    if (nodefs) {
                        LOG6("\t\t\tUse of field [ " << use.first->toString() << " : " << use.second
                                                     << " ] does not have a def");
                        // Get stage for the field use
                        auto field_min_stage = get_min_stage(use.first);
                        LOG5("f_use_stage: " << field_min_stage);
                        // Get earliest min stage for field 2 defs
                        int field2_min_stage = Device::numStages();
                        for (auto &def2 : get_slice_defs(f2sl)) {
                            int field2_def_min_stage = get_min_stage(def2.first);
                            LOG5("f2_def_stage: " << field2_def_min_stage << " Implicit: "
                                                  << def2.second->is<ImplicitParserInit>());
                            if ((field2_def_min_stage < field2_min_stage) &&
                                !def2.second->is<ImplicitParserInit>())
                                field2_min_stage = field2_def_min_stage;
                        }
                        // If field min stage is before field2 min stage do not throw the
                        // error; The equal is for the case field2 has a read in the same
                        // stage that field1 has a write
                        if (field_min_stage <= field2_min_stage) {
                            LOG1("\t\t\tField min stage " << field_min_stage
                                                          << " before overlay min stage "
                                                          << field2_min_stage);
                        } else {
                            // Check if overlayed field2 slice has defs which
                            // may corrupt field1
                            bool field2_has_def = false;
                            const auto &sl2_defs = get_slice_defs(f2sl);
                            if (!sl2_defs.empty()) {
                                if (!((sl2_defs.size() == 1) &&
                                      sl2_defs.begin()->second->is<ImplicitParserInit>())) {
                                    field2_has_def = true;
                                }
                            }

                            if (!field2_has_def) {
                                LOG6("\t\t\tOverlay has no def, skipping");
                                continue;
                            }

                            auto field_slice =
                                field.name + fsl.field_slice().formatAsSlice(field.size);
                            auto overlay_slice =
                                field2->name + f2sl.field_slice().formatAsSlice(field2->size);
                            auto field_cont_slice =
                                cont.toString() + csl.formatAsSlice(cont.size());
                            auto overlay_cont_slice =
                                cont.toString() + csl2.formatAsSlice(cont.size());
                            auto loc = use.first->toString();

                            uninit_reads.emplace(field_slice, overlay_slice, field_cont_slice,
                                                 overlay_cont_slice, loc);
                            LOG1("Uninitialized Read with Overlay found - "
                                 << "Field : " << field_slice << " in " << field_cont_slice
                                 << " Overlay : " << overlay_slice << " in " << overlay_cont_slice
                                 << " at " << loc);
                        }
                    } else {
                        LOG6("\t\t\tUse of field [ " << use.first->toString() << " : " << use.second
                                                     << " ] has def(s)");
                        for (auto &def : defs_of_use) {
                            LOG7("\t\t\t\tDef at [ " << def.first->toString() << " : " << def.second
                                                     << " ]");
                        }
                    }
                }
            }
        }
    }

    // Pretty print warning for all uninit reads
    if (uninit_reads.size() > 0) {
        std::stringstream ss;
        ss << " (CRITICAL)" << std::endl;
        ss << "Following field(s) have an uninitialized read with an overlay which can potentially"
              " cause invalid field value for specified usage"
           << std::endl;

        std::vector<std::string> headers;
        headers.push_back("Field");
        if (LOGGING(1)) headers.push_back("Field Container Slice");
        headers.push_back("Overlay Field");
        if (LOGGING(1)) headers.push_back("Overlay Container Slice");
        headers.push_back("Usage");
        TablePrinter tp(ss, headers, TablePrinter::Align::LEFT);
        for (auto &u : uninit_reads) {
            std::vector<std::string> row;
            row.push_back(u.field_slice.c_str());
            if (LOGGING(1)) row.push_back(u.field_cont_slice.c_str());
            row.push_back(u.overlay_slice.c_str());
            if (LOGGING(1)) row.push_back(u.overlay_cont_slice.c_str());
            row.push_back(u.loc.c_str());
            tp.addRow(row);
        }
        tp.print();

        ss << "Please initialize the fields in the program to ensure correctness during runtime"
           << std::endl;
        ss << "NOTES: " << std::endl;
        ss << " - For fields with headers setValid() in MAU please initialize all fields in"
              " the header"
           << std::endl;
        ss << " - For padding fields please use @padding annotation on the field" << std::endl;
        ss << " - For metadata fields @pa_auto_init_metadata can be used to auto initialize"
              " all metadata fields"
           << std::endl;
        ss << " - Warning can be ignored if uninitialized reads are intentional and do not affect"
              " program execution in any way"
           << std::endl;
        ss << " - P4 Language Spec states an uninitialized field can have an unspecified value and"
              " PHV allocation overlays such fields for more efficient packing"
           << std::endl;

        warning(BFN::ErrorType::WARN_UNINIT_OVERLAY, "%s", ss.str());
    }
}

// CheckUninitializedAndOverlayedReads
CheckUninitializedAndOverlayedReads::CheckUninitializedAndOverlayedReads(
    const FieldDefUse &defuse, const PhvInfo &phv, const PHV::Pragmas &pragmas,
    const BFN_Options &options) {
    auto *deps = new DependencyGraph();
    addPasses(
        {new FindDependencyGraph(phv, *deps, &options, ""_cs, "Before Uninitialized Read Check"_cs),
         new FindUninitializedAndOverlayedReads(defuse, phv, pragmas, *deps)});
}
