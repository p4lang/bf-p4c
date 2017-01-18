//#include "tofino/intrinsic_metadata.p4"

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

        field_m_18 : 18;
        field_n_6  : 6;

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


action action_0(p0){
    modify_field(pkt.field_i_8, p0);
}

action action_1(p1){
    modify_field(pkt.field_j_8, p1);
}

table table_0 {
    reads {
        pkt.field_m_18 : exact;
    }
    
    actions {
        action_0;
    }
    size : 262144;
}

table table_1 {
    reads {
       pkt.field_j_8 : exact;
    }
    actions {
       action_1;
    }
    size : 256;
}

control ingress {
    apply(table_1);
    apply(table_0);
}