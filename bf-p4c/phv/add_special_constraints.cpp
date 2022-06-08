#include "bf-p4c/arch/bridge_metadata.h"
#include "bf-p4c/phv/add_special_constraints.h"

Visitor::profile_t AddSpecialConstraints::init_apply(const IR::Node* root) {
    profile_t rv = Inspector::init_apply(root);
    seen_hdr_i.clear();
    return rv;
}

bool AddSpecialConstraints::preorder(const IR::BFN::ChecksumVerify* verify) {
    if (!verify->dest) return false;
    const PHV::Field* field = phv_i.field(verify->dest->field);
    if (!field) return false;
    pragmas_i.pa_container_sizes().add_constraint(field, { PHV::Size::b16 });
    return true;
}

bool AddSpecialConstraints::preorder(const IR::BFN::ChecksumResidualDeposit* get) {
    if (!get->dest) return false;
    const PHV::Field* field = phv_i.field(get->dest->field);
    if (!field) return false;
    pragmas_i.pa_container_sizes().add_constraint(field, { PHV::Size::b16 });
    return true;
}

bool AddSpecialConstraints::preorder(const IR::Concat* concat) {
    PHV::Field* f1 = phv_i.field(concat->left);
    PHV::Field* f2 = phv_i.field(concat->right);
    if ((f1 != f2) && f2) {
        if (concat->left->is<IR::Constant>()) {
            LOG3("Setting field " << f2->name << " as upcasted because of a concat operation");
            f2->set_upcasted(true);
        }
    }
    return true;
}

bool AddSpecialConstraints::preorder(const IR::Cast* cast) {
    const IR::Type* srcType = cast->expr->type;
    const IR::Type* dstType = cast->destType;

    if (srcType->is<IR::Type_Bits>() && dstType->is<IR::Type_Bits>() &&
        srcType->width_bits() < dstType->width_bits()) {
        PHV::Field* f = phv_i.field(cast->expr);
        if (f) {
            LOG3("Setting field " << f->name << " as upcasted because of a cast operation");
            f->set_upcasted(true);
        }
    }
    return true;
}

bool AddSpecialConstraints::preorder(const IR::ConcreteHeaderRef* hr) {
#ifdef HAVE_FLATROCK
    if (Device::currentDevice() == Device::FLATROCK) {
        const auto* ts = hr->type->to<IR::Type_Struct>();
        const auto* md = hr->ref->to<IR::Metadata>();
        if (md && ts && ts->name == "ingress_intrinsic_metadata_for_tm_t") {
            static std::vector<std::string> mdp_vld_vec = {
                "icrc_enable",
                "drop",
                "pgen_trig_vld",
                "iafc_vld",
                "lq_vld",
                "pkt_expan_idx_vld",
                "ucast_egress_port.$valid",
                "mcast_grp_b.$valid",
                "mcast_grp_a.$valid",
                "mirror_bitmap.$valid",
                "copy_to_cpu",
                "perfect_hash_table_id",
                "enable_mcast_cutthru",
                "disable_ucast_cutthru",
                "deflect_on_drop",
            };

            if (seen_hdr_i.count(md->name)) return true;
            seen_hdr_i.emplace(md->name);

            LOG3("Adding byte pack constraint for " << md->name);
            PHV::PackingLayout packing;
            packing.gress = INGRESS;

            // Add padding if we don't have a multiple of 8b
            if (8 - (mdp_vld_vec.size() % 8))
                packing.layout.push_back(
                    PHV::PackingLayout::FieldRangeOrPadding(8 - (mdp_vld_vec.size() % 8)));

            // Add the fields
            for (auto mdp_field : mdp_vld_vec) {
                cstring field_name = md->name + "." + mdp_field;
                const auto* field = phv_i.field(field_name);
                // The field function matches suffixes, so make sure we have the field we actually
                // care about
                if (field && field->name == field_name) {
                    LOG5("  Adding: " << field_name);
                    packing.layout.push_back(PHV::PackingLayout::FieldRangeOrPadding(
                        {field, le_bitrange(StartLen(0, field->size))}));
                } else {
                    LOG5("  Couldn't find: " << field_name);
                    packing.layout.push_back(PHV::PackingLayout::FieldRangeOrPadding(1));
                }

                // FIXME: setting ucast_egress_port.$valid fails if the group is assigned to a 16b
                // container. PHV alloc should handle this automatically.
                if (mdp_field == "ucast_egress_port.$valid")
                    pragmas_i.pa_container_sizes().add_constraint(field, {PHV::Size::b8});
            }

            auto res = pragmas_i.pa_byte_pack().add_compiler_added_packing(packing);
            if (!res.ok()) error(*res.error);
        }
    }
#endif  /* HAVE_FLATROCK */
    return true;
}

void AddSpecialConstraints::end_apply() {
    // decaf constraint
    for (auto f : decaf_i.rewrite_deparser.must_split_fields) {
        auto field = phv_i.field(f);
        if (field->size == 16) {
            pragmas_i.pa_container_sizes().add_constraint(field,
                                                   {PHV::Size::b8, PHV::Size::b8});
        } else if (field->size == 32) {
            pragmas_i.pa_container_sizes().add_constraint(field,
                                                   {PHV::Size::b16, PHV::Size::b16});
        }
    }

    // Mirror metadata allocation constraint:
    for (auto gress : {INGRESS, EGRESS}) {
        auto* mirror_id = phv_i.field(
                cstring::to_cstring(gress) + "::" + BFN::COMPILER_META + ".mirror_id");
        if (mirror_id) {
            mirror_id->set_no_split(true);
            mirror_id->set_deparsed_bottom_bits(true);
            if (Device::currentDevice() == Device::TOFINO) {
                pragmas_i.pa_container_sizes().add_constraint(mirror_id, {PHV::Size::b16}); }
        }
        auto* mirror_src = phv_i.field(
                cstring::to_cstring(gress) + "::" + BFN::COMPILER_META + ".mirror_source");
        if (mirror_src) {
            mirror_src->set_no_split(true);
            mirror_src->set_deparsed_bottom_bits(true);
            pragmas_i.pa_container_sizes().add_constraint(mirror_src, { PHV::Size::b8 });
        }
    }

    // The meter hack, all destination of meter color go to 8-bit container if they can't be
    // rotated. This was relaxed from the original constraint, see P4C-3019.
    for (const auto* f : actions_i.meter_color_dests()) {
        auto* meter_color_dest = phv_i.field(f->id);
        meter_color_dest->set_no_split(true);

        // Meter color destination have constraint relative to immediate position which make it
        // difficult to allocate them on 16-bit or 32-bit PHV.
        meter_color_dest->set_prefer_container_size(PHV::Size::b8);
        if (actions_i.is_meter_color_destination_8bit(f))
            pragmas_i.pa_container_sizes().add_constraint(f, { PHV::Size::b8 });
        else
            meter_color_dest->set_prefer_container_size(PHV::Size::b8);
    }

    // Force Ghost metadata field on 32-bit container for now until we have a way to define
    // the required constraints (consecutive container for all the field of this header).
    const std::map<cstring, PHV::Field> &fields = phv_i.get_all_fields();
    for (auto& kv : fields) {
        const PHV::Field &field = kv.second;
        if (field.name.startsWith("ghost::gh_intr_md") && !field.pov) {
            auto* ghost_field = phv_i.field(field.id);
            pragmas_i.pa_container_sizes().add_constraint(ghost_field, { PHV::Size::b32 });
            ghost_field->set_no_split(true);
        }
    }
}
