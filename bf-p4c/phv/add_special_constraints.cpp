#include "bf-p4c/arch/bridge_metadata.h"
#include "bf-p4c/phv/add_special_constraints.h"

bool AddSpecialConstraints::preorder(const IR::BFN::DeparserParameter* param) {
    auto field = phv_i.field(param->source->field);

    if (!field->deparsed_bottom_bits()) {
        // choose best fit container for ones that are shift-able
        if (field->size > 8) {
            auto container_size = ((field->size + 7) / 8) * 8;
            pragmas_i.pa_container_sizes().add_constraint(field, { PHV::Size(container_size) });
        } else {
            field->setToBottomByte();
        }
    }

    return false;
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
