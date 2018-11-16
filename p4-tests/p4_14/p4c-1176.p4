#include "tofino/intrinsic_metadata.p4"
#include "tofino/stateful_alu_blackbox.p4"

metadata ingress_intrinsic_metadata_t ingress_metadata;

@pragma field_list_field_slice ig_intr_md.ingress_port 6 0 // Ports 0-71 ( local to the pipeline )
field_list ingress_pv_fields {
    ig_intr_md.ingress_port;
}

field_list_calculation ingress_pv_hash {
    input { ingress_pv_fields; }
    algorithm { identity; }
    output_width : 19;
}

register ingress_vlan_mbr_reg{
    width : 1;
    static : ingress_vlan_mbr;
    instance_count : 1024;
}

blackbox stateful_alu ingress_vlan_mbr_alu{
    reg: ingress_vlan_mbr_reg;
    update_lo_1_value: read_bitc;
    output_value: alu_lo;
}

action ingress_vlan_mbr_check() {
    ingress_vlan_mbr_alu.execute_stateful_alu_from_hash(ingress_pv_hash);
}

table ingress_vlan_mbr {
    actions { ingress_vlan_mbr_check; }
    default_action : ingress_vlan_mbr_check;
    size : 1;
}

parser start {
    return ingress;
}

control ingress {
    apply(ingress_vlan_mbr);
}
