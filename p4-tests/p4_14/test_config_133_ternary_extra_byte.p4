#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */
header_type pkt_t {
    fields {
        field_a_32 : 32;
        field_b_32 : 32;
        field_c_32 : 32;
        field_d_32 : 32;

        field_e_16 : 16;
        field_f_16 : 16;
        field_g_16 : 16;
        field_h_16 : 16;

        field_i_8 : 8;
        field_j_8 : 8;
        field_k_8 : 8;
        field_l_8 : 8;

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


action action_0(param0){
    modify_field(pkt.field_f_16, param0);
}
action do_nothing(){} 

table table_0 {
    reads {
        pkt.field_a_32 : ternary;
        pkt.field_i_8 : ternary;
        pkt.field_j_8 : ternary;
        pkt.field_b_32 : ternary;
        pkt.field_k_8 : ternary;
    }
    actions {
        action_0;
        do_nothing;
    }
    size : 512;
}

/* Main control flow */

control ingress {
    apply(table_0);
}
