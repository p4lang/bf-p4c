#include "bf-p4c/phv/add_special_constraints.h"

void AddSpecialConstraints::end_apply() {
    // Mirror metadata allocation constraint:
    for (auto gress : {INGRESS, EGRESS}) {
        auto* mirror_id = phv_i.field(
                cstring::to_cstring(gress) + "::" + "compiler_generated_meta.mirror_id");
        if (mirror_id) {
            mirror_id->set_no_split(true);
            mirror_id->set_deparsed_bottom_bits(true);
            pragmas_i.pa_container_sizes().add_constraint(mirror_id, { PHV::Size::b16 });
        }
        auto* mirror_src = phv_i.field(
                cstring::to_cstring(gress) + "::" + "compiler_generated_meta.mirror_source");
        if (mirror_src) {
            mirror_src->set_no_split(true);
            mirror_src->set_deparsed_bottom_bits(true);
            pragmas_i.pa_container_sizes().add_constraint(mirror_src, { PHV::Size::b8 });
        }
    }

    // HACK WARNING:
    // The meter hack, all destination of meter color go to 8-bit container.
    // TODO(yumin): remove this once this hack is removed in mau.
    for (const auto* f : actions_i.meter_color_dests()) {
        auto* meter_color_dest = phv_i.field(f->id);
        meter_color_dest->set_no_split(true);
        pragmas_i.pa_container_sizes().add_constraint(f, { PHV::Size::b8 });
    }
}
