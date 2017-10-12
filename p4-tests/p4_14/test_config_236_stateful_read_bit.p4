#include "tofino/intrinsic_metadata.p4"
#include "tofino/stateful_alu_blackbox.p4"

/* Sample P4 program */
header_type pkt_t {
    fields {
        field_a_32 : 32;
        field_b_32 : 32;
        field_c_32 : 32;
        field_d_32 : 32;

        field_e_16 : 1;
        field_f_16 : 16;
        field_g_16 : 16;
        field_h_16 : 16;

        field_i_16 : 16;
        field_j_16 : 16;
        field_k_8 : 8;
        field_l_8 : 8;

        pad_0 : 7;
        single_bit : 1;
        pad_1 : 7;
    }
}

parser start {
    return parse_ethernet;
}

header pkt_t pkt;

parser parse_ethernet {
    extract(pkt);
    return ingress;
}

register reg_0 {
    width : 1;
    instance_count : 131072;
}

/*
blackbox stateful_alu bbox_0 {
    reg: reg_0;
    update_lo_1_value : read_bit;
    output_value : alu_lo;
    output_dst : pkt.single_bit;
}

blackbox stateful_alu bbox_1 {
    reg: reg_0;
    update_lo_1_value : read_bitc;
    output_value : alu_lo;
    output_dst : pkt.single_bit;
}
*/

blackbox stateful_alu bbox_0 {
    reg: reg_0;
    output_value : register_lo;
    output_dst : pkt.single_bit;
}

action action_0(idx){
    bbox_0.execute_stateful_alu(idx);
}


table table_0 {
    reads {
        pkt.field_a_32 : ternary;
    }
    actions {
        action_0;
    }
    size : 4096;
}

/* Main control flow */

control ingress {
    apply(table_0);
}
