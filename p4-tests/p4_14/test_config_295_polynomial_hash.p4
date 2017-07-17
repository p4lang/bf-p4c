
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
    return parse_pkt;
}

header pkt_t pkt;

parser parse_pkt {
    extract(pkt);
    return ingress;
}


field_list simple_field_list {
    pkt.field_a_32;
    pkt.field_b_32;
    pkt.field_e_16;
    pkt.field_f_16;
    pkt.field_i_8;
    pkt.field_j_8;
}


field_list_calculation reproduce_crc32 {
    input { simple_field_list; }
    algorithm : poly_0x104c11db7_init_0x0_xout_0xffffffff;
    /* algorithm : crc32; */
    output_width : 32;
}


field_list_calculation reproduce_crc16 {
    input { simple_field_list; }
    algorithm : poly_0x11021_not_rev_xout_0x0;
    /* algorithm : crc16; */
    output_width : 16;
}

field_list_calculation reproduce_crc8 {
    input { simple_field_list; }
    algorithm : crc_8_extend;
    output_width : 16;
}

field_list_calculation reproduce_crc16b {
    input { simple_field_list; }
    algorithm : poly_0x11021_not_rev_xout_0x0_msb;
    output_width : 8;
}


action a0() {
    modify_field_with_hash_based_offset(pkt.field_d_32, 0, reproduce_crc32, 2147483648);
}

action a1() {
    modify_field_with_hash_based_offset(pkt.field_h_16, 0, reproduce_crc16, 0x10000);
}

action a2() {
    modify_field_with_hash_based_offset(pkt.field_g_16, 0, reproduce_crc8, 0x10000);
}

action a3() {
    modify_field_with_hash_based_offset(pkt.field_k_8, 0, reproduce_crc16b, 0x100);
}

action do_nothing(){}


table table_0 {
    reads {
        pkt.field_a_32 : lpm;
    }
    
    actions {
        a0;
        do_nothing;
    }
    size : 512;
}

table table_1 {
    reads {
        pkt.field_a_32 : lpm;
    }
    
    actions {
        a1;
        do_nothing;
    }
    size : 512;
}

@pragma stage 1
table table_2 {
    reads {
        pkt.field_a_32 : lpm;
    }
    
    actions {
        a2;
        do_nothing;
    }
    size : 512;
}

@pragma stage 2
table table_3 {
    reads {
        pkt.field_a_32 : lpm;
    }
    
    actions {
        a3;
        do_nothing;
    }
    size : 512;
}

control ingress {
    apply(table_0);
    apply(table_1);
    apply(table_2);
    apply(table_3);
}