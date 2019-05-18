#include <regex>
#include "bf-p4c/phv/add_special_constraints.h"

bool AddSpecialConstraints::preorder(const IR::BFN::Deparser* deparser) {
    for (auto prim : deparser->emits) {
        if (auto ef = prim->to<IR::BFN::EmitField>()) {
            auto field = phv_i.field(ef->source->field);
            auto pov_bit = phv_i.field(ef->povBit->field);

            std::string field_name(pov_bit->name);
            std::smatch res;
            std::regex regex(R"(_v[0-9]+\.\$valid)");

            if (std::regex_search(field_name, res, regex)) {
                if (field->size == 8) {
                    field->set_no_pack(true);
                } else if (field->size == 16) {
                    pragmas_i.pa_container_sizes().add_constraint(
                        field, { PHV::Size::b8, PHV::Size::b8 });
                } else if (field->size == 32) {
                    pragmas_i.pa_container_sizes().add_constraint(
                        field, { PHV::Size::b16, PHV::Size::b16 });
                }
            }
        }
    }

    return true;
}

bool AddSpecialConstraints::preorder(const IR::BFN::ChecksumVerify* verify) {
    if (!verify->dest) return false;
    const PHV::Field* field = phv_i.field(verify->dest->field);
    if (!field) return false;
    pragmas_i.pa_container_sizes().add_constraint(field, { PHV::Size::b16 });
    return true;
}

bool AddSpecialConstraints::preorder(const IR::BFN::ChecksumGet* get) {
    if (!get->dest) return false;
    const PHV::Field* field = phv_i.field(get->dest->field);
    if (!field) return false;
    pragmas_i.pa_container_sizes().add_constraint(field, { PHV::Size::b16 });
    return true;
}

void AddSpecialConstraints::end_apply() {
    // Mirror metadata allocation constraint:
    for (auto gress : {INGRESS, EGRESS}) {
        auto* mirror_id = phv_i.field(
                cstring::to_cstring(gress) + "::" + "compiler_generated_meta.mirror_id");
        if (mirror_id) {
            mirror_id->set_no_split(true);
            mirror_id->set_deparsed_bottom_bits(true);
            if (Device::currentDevice() == Device::TOFINO) {
                pragmas_i.pa_container_sizes().add_constraint(mirror_id, {PHV::Size::b16}); }
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
