#include "collect_hardware_constrained_fields.h"


namespace BFN {

IR::Member* create_member(cstring hdr, cstring member) {
    return new IR::Member(new IR::PathExpression(IR::ID(hdr)), member);
}

void AddHardwareConstrainedFields::postorder(IR::BFN::Pipe *pipe) {
    bool disable_reserved_i2e_drop_implementation = false;
    for (auto anno : pipe->global_pragmas) {
        if (anno->name != PragmaDisableI2EReservedDropImplementation::name) continue;
        disable_reserved_i2e_drop_implementation = true;
    }
    cstring ig_intr_md_for_tm;
#if HAVE_FLATROCK
    if (Device::currentDevice() != Device::FLATROCK) {
#endif
        ig_intr_md_for_tm = "ingress::ig_intr_md_for_tm";
#if HAVE_FLATROCK
    } else {
        ig_intr_md_for_tm = "ig_intr_md_for_tm";
    }
#endif
    ordered_map<cstring, IR::BFN::HardwareConstrainedField*> name_to_field;
    name_to_field["mcast_grp_a"] = new IR::BFN::HardwareConstrainedField(
        create_member(ig_intr_md_for_tm, "mcast_grp_a"));
    name_to_field["mcast_grp_b"] = new IR::BFN::HardwareConstrainedField(
        create_member(ig_intr_md_for_tm, "mcast_grp_b"));
    name_to_field["ucast_egress_port"] = new IR::BFN::HardwareConstrainedField(
        create_member(ig_intr_md_for_tm, "ucast_egress_port"));
    name_to_field["level1_mcast_hash"] = new IR::BFN::HardwareConstrainedField(
        create_member(ig_intr_md_for_tm, "level1_mcast_hash"));
    name_to_field["level2_mcast_hash"] = new IR::BFN::HardwareConstrainedField(
        create_member(ig_intr_md_for_tm, "level2_mcast_hash"));
    name_to_field["level1_exclusion_id"] = new IR::BFN::HardwareConstrainedField(
        create_member(ig_intr_md_for_tm, "level1_exclusion_id"));
    name_to_field["level2_exclusion_id"] = new IR::BFN::HardwareConstrainedField(
        create_member(ig_intr_md_for_tm, "level2_exclusion_id"));
    name_to_field["rid"] =new IR::BFN::HardwareConstrainedField(
        create_member(ig_intr_md_for_tm, "rid"));

#if HAVE_FLATROCK
    if (Device::currentDevice() != Device::FLATROCK) {
#endif
        cstring ig_intr_md_for_dprsr = "ingress::ig_intr_md_for_dprsr";
        name_to_field["resubmit_type"] = new IR::BFN::HardwareConstrainedField(
            create_member(ig_intr_md_for_dprsr, "resubmit_type"));
        name_to_field["ig_digest_type"] = new IR::BFN::HardwareConstrainedField(
            create_member(ig_intr_md_for_dprsr, "digest_type"));
        name_to_field["ig_mirror_type"] = new IR::BFN::HardwareConstrainedField(
            create_member(ig_intr_md_for_dprsr, "mirror_type"));
        name_to_field["drop_ctl"] = new IR::BFN::HardwareConstrainedField(
            create_member(ig_intr_md_for_dprsr, "drop_ctl"));
#if HAVE_FLATROCK
    }
#endif
    cstring eg_intr_md_for_dprsr;

#if HAVE_FLATROCK
    if (Device::currentDevice() != Device::FLATROCK) {
#endif
        eg_intr_md_for_dprsr = "egress::eg_intr_md_for_dprsr";
#if HAVE_FLATROCK
    } else {
        eg_intr_md_for_dprsr = "eg_intr_md_for_dprsr";
    }
#endif

    name_to_field["eg_mirror_type"] = new IR::BFN::HardwareConstrainedField(
        create_member(eg_intr_md_for_dprsr, "mirror_type"));

    cstring eg_intr_md;
#if HAVE_FLATROCK
    if (Device::currentDevice() != Device::FLATROCK) {
#endif
        eg_intr_md = "egress::eg_intr_md";
#if HAVE_FLATROCK
    } else {
        eg_intr_md = "eg_intr_md";
    }
#endif

    name_to_field["egress_port"] = new IR::BFN::HardwareConstrainedField(
        create_member(eg_intr_md, "egress_port"));

    name_to_field["egress_port"]->constraint_type.setbit(
        IR::BFN::HardwareConstrainedField::DEPARSED_BOTTOM_BITS);
    name_to_field["mcast_grp_a"]->constraint_type.setbit(
        IR::BFN::HardwareConstrainedField::DEPARSED_BOTTOM_BITS);
    name_to_field["mcast_grp_b"]->constraint_type.setbit(
        IR::BFN::HardwareConstrainedField::DEPARSED_BOTTOM_BITS);
    name_to_field["ucast_egress_port"]->constraint_type.setbit(
        IR::BFN::HardwareConstrainedField::DEPARSED_BOTTOM_BITS);

    if (Device::currentDevice() == Device::TOFINO) {
        name_to_field["level1_mcast_hash"]->constraint_type.setbit(
            IR::BFN::HardwareConstrainedField::DEPARSED_BOTTOM_BITS);
        name_to_field["level2_mcast_hash"]->constraint_type.setbit(
            IR::BFN::HardwareConstrainedField::DEPARSED_BOTTOM_BITS);
        name_to_field["level1_exclusion_id"]->constraint_type.setbit(
            IR::BFN::HardwareConstrainedField::DEPARSED_BOTTOM_BITS);
        name_to_field["level2_exclusion_id"]->constraint_type.setbit(
            IR::BFN::HardwareConstrainedField::DEPARSED_BOTTOM_BITS);
        name_to_field["rid"]->constraint_type.setbit(
            IR::BFN::HardwareConstrainedField::DEPARSED_BOTTOM_BITS);
        name_to_field["mcast_grp_a"]->constraint_type.setbit(
            IR::BFN::HardwareConstrainedField::INVALIDATE_FROM_ARCH);
        name_to_field["mcast_grp_b"]->constraint_type.setbit(
            IR::BFN::HardwareConstrainedField::INVALIDATE_FROM_ARCH);
        name_to_field["ucast_egress_port"]->constraint_type.setbit(
            IR::BFN::HardwareConstrainedField::INVALIDATE_FROM_ARCH);
        name_to_field["resubmit_type"]->constraint_type.setbit(
            IR::BFN::HardwareConstrainedField::INVALIDATE_FROM_ARCH);
        name_to_field["ig_digest_type"]->constraint_type.setbit(
            IR::BFN::HardwareConstrainedField::INVALIDATE_FROM_ARCH);

        // field that are required to be initialized to zero based on requirement from architecture.
        // ig_intr_md_for_dprsr.mirror_type must be init to zero to workaround ibuf hardware bug.
        // It is validated by default in parser, unless explicitly disabled by the pragma
        // @disable_reserved_i2e_drop_implementation.
        // JIRA-DOC: See  P4C-4507.
        if (disable_reserved_i2e_drop_implementation) {
            name_to_field["ig_mirror_type"]->constraint_type.setbit(
                IR::BFN::HardwareConstrainedField::INVALIDATE_FROM_ARCH);
        }

        name_to_field["eg_mirror_type"]->constraint_type.setbit(
            IR::BFN::HardwareConstrainedField::INVALIDATE_FROM_ARCH);
        name_to_field["drop_ctl"]->constraint_type.setbit(
            IR::BFN::HardwareConstrainedField::INIT_BY_ARCH);
        name_to_field["ig_mirror_type"]->constraint_type.setbit(
            IR::BFN::HardwareConstrainedField::INIT_BY_ARCH);
    }

    // Treat ig_intr_md_for_dprsr.mirror_type the same way in Tofino2
    if (Device::currentDevice() == Device::JBAY) {
        if (disable_reserved_i2e_drop_implementation) {
            name_to_field["ig_mirror_type"]->constraint_type.setbit(
                IR::BFN::HardwareConstrainedField::INVALIDATE_FROM_ARCH);
        }

        name_to_field["ig_mirror_type"]->constraint_type.setbit(
            IR::BFN::HardwareConstrainedField::INIT_BY_ARCH);
    }

    ordered_set<cstring> ingress_fields = {
        "mcast_grp_a", "mcast_grp_b", "ucast_egress_port", "level1_mcast_hash", "level2_mcast_hash",
        "level1_exclusion_id", "level2_exclusion_id", "rid"};
#if HAVE_FLATROCK
    if (Device::currentDevice() != Device::FLATROCK) {
#endif
        for (auto name : {"resubmit_type", "ig_digest_type", "ig_mirror_type", "drop_ctl"})
            ingress_fields.insert(name);
#if HAVE_FLATROCK
    }
#endif
    for (auto name : ingress_fields) {
        pipe->thread[INGRESS].hw_constrained_fields.push_back(name_to_field[name]);
    }

    auto egress_fields = { "eg_mirror_type", "egress_port" };
    for (auto name : egress_fields) {
        pipe->thread[EGRESS].hw_constrained_fields.push_back(name_to_field[name]);
    }
}


}  // namespace BFN
